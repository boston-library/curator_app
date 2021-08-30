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
end
