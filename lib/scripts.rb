# frozen_string_literal: true

require 'csv'

module Scripts
  # verify data migrated from Commonwealth/Fedora
  # @param path_to_manifest_csv [String] full path to export manifest
  def self.verify_migration(path_to_manifest_csv)
    puts "Starting verification from CSV: #{path_to_manifest_csv}"
    verify_output = []
    all_verified = []
    export_data = CSV.read(path_to_manifest_csv)
    export_data[1..(export_data.count - 1)].each do |export_row|
      verified = false
      error = ''
      model_type = export_row[0]
      ark_id = export_row[1]
      attachment_type = export_row[2]
      parent_ark_id = export_row[3]
      filename_base = export_row[4]

      rec_class = if !model_type.match? /ActiveStorage/
                    "Curator::#{model_type}".constantize
                  else
                    model_type.constantize
                  end
      if ark_id.present? && rec_class.to_s.match?(/Curator/)
        if rec_class.find_by(ark_id: ark_id)
          verified = true
        else
          error = "Could not find #{rec_class.to_s} with ark id: #{ark_id}"
        end
      elsif parent_ark_id.present? && filename_base.present?
        parent = Curator::DigitalObject.find_by(ark_id: parent_ark_id)
        if parent
          fs_query = if rec_class < Curator::Filestreams::FileSet
                       rec_class.where(file_set_of_id: parent.id, file_name_base: filename_base)
                     else
                       Curator::Filestreams::FileSet.where(file_set_of_id: parent.id, file_name_base: filename_base)
                     end
          if fs_query.count > 1
            error = "Found multiple #{rec_class.to_s} with parent ark id: #{parent_ark_id} and file_name_base: #{filename_base}"
          elsif fs_query.blank?
            error = "Could not find #{rec_class.to_s} with parent ark id: #{parent_ark_id} and file_name_base: #{filename_base}"
          end
          next unless fs_query.count == 1

          if rec_class < Curator::Filestreams::FileSet
            verified = true
          else
            fs = fs_query.first
            if fs.public_send(attachment_type.to_sym).attached?
              blob = fs.public_send(attachment_type.to_sym).blob
              if blob.service.exist?(blob.key)
                verified = true
              else
                error = "Could not find #{attachment_type} blob in Azure for #{fs.class} with id: #{fs.id} and ark id: #{fs.ark_id}"
              end
            else
              error = "Could not find attachment #{attachment_type} for #{fs.class} with id: #{fs.id} and ark id: #{fs.ark_id}"
            end
          end
        else
          error = "Could not find parent Curator::DigitalObject with ark id: #{parent_ark_id}"
        end
      end
      verify_output << (export_row + [verified.to_s, error])
      all_verified << verified
    end

    new_csv = path_to_manifest_csv.gsub(/\.csv\Z/, '_VERIFICATION-REPORT.csv')
    CSV.open(new_csv, 'w') do |csv_obj|
      csv_obj << (export_data[0] + %w(verified errors))
      verify_output.each { |v| csv_obj << v }
    end

    if all_verified.include?(false)
      puts "VERIFICATION FAILED! See #{new_csv} for details."
      false
    else
      puts 'VERIFICATION PASSED! All objects and attachments present.'
      true
    end
  end

  def self.verify_migration_new(path_to_manifest_csv)
    puts "Starting verification from CSV: #{path_to_manifest_csv}"
    VerifyMigration.new(path_to_manifest_csv).verify!
  end

  class VerifyMigration
    class VerifyError < StandardError
      attr_reader :rec_class

      def initialize(rec_class = nil)
        @rec_class = rec_class.to_s
        super('Default Verify Error Message!')
      end
    end

    class UnknownRecordClass < VerifyError
      def message
        "Unknown class #{rec_class}"
      end
    end

    class RecordNotFoundError < VerifyError
      attr_reader :ark_id

      def initialize(rec_class, ark_id)
        @ark_id = ark_id
        super(rec_class)
      end

      def message
        "Could not find #{rec_class} with ark id: #{ark_id}"
      end
    end

    class ParentRecordNotFound < RecordNotFoundError
      def message
        "Could not find parent #{rec_class} with ark id: #{ark_id}"
      end
    end

    class FileSetQueryBlank < ParentRecordNotFound
      attr_reader :filename_base

      def initialize(rec_class, ark_id, filename_base)
        @filename_base = filename_base
        super(rec_class, ark_id)
      end

      def message
        "Could not find #{rec_class} with parent ark id: #{ark_id} and file_name_base: #{filename_base}"
      end
    end

    class FileSetQueryMultiple < FileSetQueryBlank
      def message
        "Found multiple #{rec_class} with parent ark id: #{ark_id} and file_name_base: #{filename_base}"
      end
    end

    class AttachmentMissing < VerifyError
      attr_reader :fs_id, :fs_ark_id, :attachment_type

      def initialize(fs_class, fs_ark_id, fs_id, attachment_type)
        @fs_id = fs_id
        @fs_ark_id = fs_ark_id
        @attachment_type = attachment_type
        super(fs_class)
      end

      def message
        "Could not find attachment #{attachment_type} for #{rec_class} with id: #{fs_id} and ark id: #{fs_ark_id}"
      end
    end

    class AttachmentNotUploaded < AttachmentMissing
      def message
        "Could not find #{attachment_type} blob in Azure for #{rec_class} with id: #{fs_id} and ark id: #{fs_ark_id}"
      end
    end

    attr_reader :path_to_manifest_csv, :export_data, :verify_output, :all_verified

    def initialize(path_to_manifest_csv)
      @path_to_manifest_csv = path_to_manifest_csv
      @all_verified = []
      @verify_output = []
      parse_csv_rows!
    end

    def verify!
      with_single_database_connection do
        export_data[1..(export_data.count - 1)].each(&verify_row)
      end

      if all_verified.include?(false)
        puts "VERIFICATION FAILED! See #{output_csv_path} for details."
        return false
      end

      puts 'VERIFICATION PASSED! All objects and attachments present.'
      true
    ensure
      output_csv_results!
    end

    protected

    def verify_row
      lambda do |export_row|
        verified = false
        error = ''
        begin
          model_type, ark_id, attachment_type, parent_ark_id, file_name_base = export_row
          rec_class = record_class(model_type)

          if rec_class.to_s.match?(/Curator/) && ark_id.present?
            verified = true if find_record!(rec_class, ark_id)
            next
          elsif parent_ark_id.present? && filename_base.present?
            parent = find_parent_record!(parent_ark_id)
            fs_query = file_set_query(rec_class, parent, filename_base)

            raise FileSetQueryBlank.new(rec_class, parent_ark_id, filename_base) if fs_query.blank?

            raise FileSetQueryMultiple.new(rec_class, parent_ark_id, filename_base) if fs_query.count > 1

            if rec_class < Curator::Filestreams::FileSet
              verified = true
              next
            end

            fs = fs_query.first

            raise AttachmentMissing.new(fs.class, fs.ark_id, fs.id, attachment_type) if !fs.public_send(attachment_type.to_sym).attached?

            fs_blob = fs.public_send("#{attachment_type}_blob".to_sym)

            raise AttachmentNotUploaded.new(fs.class, fs.ark_id, fs.id, attachment_type) if !fs_blob.service.exist?(fs_blob.key)

            verified = true
          end
        rescue UnknownRecordClass, RecordNotFoundError, ParentRecordNotFound, FileSetQueryBlank, FileSetQueryMultiple, AttachmentMissing, AttachmentNotUploaded => e
          error = e.message
          next
        ensure
          verify_output << (export_row + [verified.to_s, error])
          all_verified << verified
        end
      end
    end

    private

    def record_class(model_type)
      case model_type
      when /ActiveStorage/
        model_type.constantize
      else
        "Curator::#{model_type}".constantize
      end
    rescue NameError
      raise UnknownRecordClass.new(model_type)
    end

    def find_record!(rec_class, ark_id)
      rec_class.find_by!(ark_id: ark_id)
    rescue ActiveRecord::RecordNotFound
      raise RecordNotFoundError.new(rec_class, ark_id)
    end

    def find_parent_record!(parent_ark_id)
      find_record!(Curator.digital_object_class, parent_ark_id)
    rescue RecordNotFoundError => e
      raise ParentRecordNotFound.new(e.rec_class, e.ark_id)
    end

    def file_set_query(rec_class, parent, filename_base)
      return rec_class.where(file_set_of_id: parent.id, file_name_base: filename_base) if rec_class < Curator::Filestreams::FileSet

      Curator::Filestreams::FileSet.where(file_set_of_id: parent.id, file_name_base: filename_base)
    end

    def parse_csv_rows!
      return @export_data if defined?(@export_data)

      @export_data = CSV.read(path_to_manifest_csv)
    end

    def output_csv_results!
      CSV.open(output_csv_path, 'w+') do |csv_obj|
        csv_obj << (export_data[0] + %w(verified errors))
        verify_output.each { |v| csv_obj << v }
      end
    end

    def output_csv_path
      path_to_manifest_csv.gsub(/\.csv\Z/, '_VERIFICATION-REPORT.csv')
    end

    def with_single_database_connection
      Curator::ApplicationRecord.connection_pool.with_connection do
        yield
      end
    end
  end
end
