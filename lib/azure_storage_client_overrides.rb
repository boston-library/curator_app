# frozen_string_literal: true

require 'concurrent'
require 'active_support/core_ext/numeric/bytes'
require 'faraday'
require 'faraday_middleware'
require 'azure/storage/blob'
require 'azure/storage/common/core/auth/shared_access_signature'
# NOTE: this override is to prevent frequent Faraday::ConnectionFailed Connection Reset by peer error.
# Increased pool size. made agents a threadsafe hash instead of a base one. removed redundant reuse_agent! method in favor of
# perfomring operation in agents method. Try Using clear method  first instead of just setting agents instance variable to nil.
module AzureStorageClientOverrides
  module BlobStorageClientOverride
    PARALLEL_UPLOAD_MAX_CORES = Concurrent.processor_count

    def create_block_blob(container, blob, content, options = {})
      size = if content.respond_to? :size
        content.size
      elsif options[:content_length]
        options[:content_length]
      else
        raise ArgumentError, "Either optional parameter 'content_length' should be set or 'content' should implement 'size' method to get payload's size."
      end

      threshold = get_single_upload_threshold(options[:single_upload_threshold])
      if size > threshold
        create_block_blob_multiple_put(container, blob, content, size, options)
      else
        create_block_blob_single_put(container, blob, content, options)
      end
    ensure
      content.close if content.respond_to?(:close) && !content.closed?
    end

    protected

    def create_block_blob_multiple_put(container, blob, content, size, options = {})
      content_type = get_or_apply_content_type(content, options[:content_type])
      content = StringIO.new(content) if content.is_a? String
      block_size = get_block_size(size)
      # Get the number of blocks
      block_count = (Float(size) / Float(block_size)).ceil
      block_list = []

      (0...block_count).each_slice(PARALLEL_UPLOAD_MAX_CORES) do |block_slice|
        slice_count = block_slice.count
        block_slice_data = content.read(block_size * slice_count)
        futures = block_slice.each_with_index.map do |block_id, block_slice_index|
          Concurrent::Promises.future(block_id, block_slice_index) do |block_id, block_slice_index|
            id = block_id.to_s.rjust(6, '0')
            put_blob_block(container, blob, id, block_slice_data.slice(block_slice_index * block_size, block_size), timeout: options[:timeout], lease_id: options[:lease_id])
            [id]
          end
        end
        completed = Concurrent::Promises.zip(*futures).value!
        block_list.concat(completed.sort)
      end

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
  end

  module CoreClientOverride
    CLIENT_POOL_SIZE = Integer(Concurrent.processor_count * ENV.fetch('RAILS_MAX_THREADS', 1).to_i).freeze

    def agents(uri)
      @agents ||= {}

      uri = URI(uri) unless uri.is_a? URI
      key = uri.host

      if @agents.key?(key)
        reuse_agent!(key)

        return @agents[key]
      end

      @agents[key] = build_http(uri)
      @agents[key]
    end

    # Empties all the http agents
    def reset_agents!
      if @agents.respond_to?(:clear)
        @agents.clear
      else
        @agents = nil
      end
    end

    private

    def reuse_agent!(key)
      @agents[key].params.clear
      @agents[key].headers.clear
    end

    def ssl_options(uri)
      ssl_opts = {}

      return ssl_opts unless uri.is_a?(URI) && uri.scheme.downcase == 'https'

      ssl_opts[:version] = self.ssl_version if self.ssl_version
      # min_version and max_version only supported in ruby 2.5
      ssl_opts[:min_version] = self.ssl_min_version if self.ssl_min_version
      ssl_opts[:max_version] = self.ssl_max_version if self.ssl_max_version
      ssl_opts[:ca_file] = self.ca_file if self.ca_file
      ssl_opts[:verify] = true
      ssl_opts
    end

    def proxy_options
      return unless %w[HTTP_PROXY HTTPS_PROXY].any? { |proxy_key| ENV.key?(proxy_key) }

      parsed = nil
      if ENV['HTTP_PROXY']
        parsed = URI.parse(ENV['HTTP_PROXY'])
      elsif ENV['HTTPS_PROXY']
        parsed = URI.parse(ENV['HTTPS_PROXY'])
      end
      parsed
    end

    def build_http(uri)
      Faraday.new(uri, ssl: ssl_options(uri), proxy: proxy_options) do |conn|
        conn.use FaradayMiddleware::FollowRedirects

        conn.adapter :net_http_persistent, pool_size: CLIENT_POOL_SIZE do |http|
          http.idle_timeout = 100
        end
      end
    end
  end
end
