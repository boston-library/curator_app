# frozen_string_literal: true

require 'azure/storage/blob'

module AzureBlobServiceOverride
  protected

  def create_block_blob_multiple_put(container, blob, content, size, options = {})
    content_type = get_or_apply_content_type(content, options[:content_type])
     content = StringIO.new(content) if content.is_a? String
     block_size = get_block_size(size)
     # Get the number of blocks
     block_count = (Float(size) / Float(block_size)).ceil
     block_list = put_blocks_in_threads(container, blob, content, block_count, block_size, options)
     # Commit the blocks put
     commit_options = {}
     commit_options[:content_type] = content_type
     commit_options[:content_encoding] = options[:content_encoding] if options[:content_encoding]
     commit_options[:content_language] = options[:content_language] if options[:content_language]
     commit_options[:content_md5] = options[:content_md5] if options[:content_md5]
     commit_options[:cache_control] = options[:cache_control] if options[:cache_control]
     commit_options[:content_disposition] = options[:content_disposition] if options[:content_disposition]
     commit_options[:metadata] = options[:metadata] if options[:metadata]
     commit_options[:timeout] = options[:timeout] if options[:timeout]
     commit_options[:request_id] = options[:request_id] if options[:request_id]
     commit_options[:lease_id] = options[:lease_id] if options[:lease_id]

     commit_blob_blocks(container, blob, block_list, commit_options)

     get_properties_options = {}
     get_properties_options[:lease_id] = options[:lease_id] if options[:lease_id]

     # Get the blob properties
     get_blob_properties(container, blob, get_properties_options)
  end


  private

  def put_blocks_in_threads(container, blob, content, block_count, block_size, options = {})
    mutex = Mutex.new
    block_threads = (0..block_count).map do |block_id|
      Thread.abort_on_exception = true
      Thread.new do
        mutex.synchronize do
          id = block_id.to_s.rjust(6, '0')
          put_blob_block(container, blob, id, content.read(block_size), timeout: options[:timeout], lease_id: options[:lease_id])
          id
        end
      end
    end
    block_threads.map(&:value)
  end
end

Azure::Storage::Blob::BlobService.send :include, AzureBlobServiceOverride
