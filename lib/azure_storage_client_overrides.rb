# frozen_string_literal: true

require 'azure/storage/blob'
require 'faraday'
require 'faraday_middleware'
require 'active_support/core_ext/numeric/bytes'
require 'azure/storage/common/core/auth/shared_access_signature'
# NOTE: this override is to prevent frequent Faraday::ConnectionFailed Connection Reset by peer error.
# Increased pool size. made agents a threadsafe hash instead of a base one. removed redundant reuse_agent! method in favor of
# perfomring operation in agents method. Try Using clear method  first instead of just setting agents instance variable to nil.
module AzureStorageClientOverrides
  module BlobStorageClientOverride
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

      put_block_blob_fiber = Fiber.new do
        block_id = 0
        while (chunk = content.read(block_size))
          id = block_id.to_s.rjust(6, "0")
          response = put_blob_block(container, blob, id, chunk, timeout: options[:timeout], lease_id: options[:lease_id])
          Fiber.yield [id]
          block_id += 1
        end
        nil
      end

      block_list = (0...block_count).map { put_block_blob_fiber.resume }

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
    def agents(uri)
      @agents ||= Concurrent::Map.new

      uri = URI(uri) unless uri.is_a? URI
      key = uri.host

      @agents.compute_if_present(key) do |agent|
        agent.params.clear
        agent.headers.clear
        agent
      end

      @agents.compute_if_absent(key) { build_http(uri) }

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

    def build_http(uri)
      ssl_options = {}
      if uri.is_a?(URI) && uri.scheme.downcase == 'https'
        ssl_options[:version] = self.ssl_version if self.ssl_version
        # min_version and max_version only supported in ruby 2.5
        ssl_options[:min_version] = self.ssl_min_version if self.ssl_min_version
        ssl_options[:max_version] = self.ssl_max_version if self.ssl_max_version
        ssl_options[:ca_file] = self.ca_file if self.ca_file
        ssl_options[:verify] = true
      end
      proxy_options = if ENV['HTTP_PROXY']
                        URI::parse(ENV['HTTP_PROXY'])
                      elsif ENV['HTTPS_PROXY']
                        URI::parse(ENV['HTTPS_PROXY'])
                      end || nil

      pool_size = ENV.fetch('RAILS_MAX_THREADS', 5)

      Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
        conn.use FaradayMiddleware::FollowRedirects

        if Rails.env.development?
          conn.response :logger, Rails.logger do |rails_logger|
            rails_logger.filter(/(Authorization:)(.+)/, '\1[REDACTED]')
          end
        end
        # conn.adapter :typhoeus, forbid_reuse: true, maxredirs: 3
        conn.adapter :net_http_persistent, pool_size: pool_size do |http|
          http.idle_timeout = 90
        end
      end
    end
  end
end
