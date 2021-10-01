# frozen_string_literal: true

require 'azure/storage/blob'

# NOTE: this override is to prevent frequent Faraday::ConnectionFailed Connection Reset by peer error.
# This will use the now threadsafe typhoeus adapter. Based on this person's patch https://github.com/Azure/azure-storage-ruby/issues/169#issuecomment-803623748
module AzureStorageCommonClientOverride
  private

  def build_http(uri)
    ssl_options = {}
    if uri.is_a?(URI) && uri.scheme.downcase == "https"
      ssl_options[:version] = self.ssl_version if self.ssl_version
      # min_version and max_version only supported in ruby 2.5
      ssl_options[:min_version] = self.ssl_min_version if self.ssl_min_version
      ssl_options[:max_version] = self.ssl_max_version if self.ssl_max_version
      ssl_options[:ca_file] = self.ca_file if self.ca_file
      ssl_options[:verify] = true
    end
    proxy_options = if ENV["HTTP_PROXY"]
                      URI::parse(ENV["HTTP_PROXY"])
                    elsif ENV["HTTPS_PROXY"]
                      URI::parse(ENV["HTTPS_PROXY"])
                    end || nil

    # pool_size = ENV.fetch('RAILS_MAX_THREADS') { 16 }.to_i * 2
    # pool_size = 16 if pool_size < 16
    request_options = { read_timeout: 240, write_timeout: 240, open_timeout: 15 }
    Faraday.new(uri, ssl: ssl_options, proxy: proxy_options, request: request_options ) do |conn|
      conn.use FaradayMiddleware::FollowRedirects
      conn.request :multipart
      conn.request :url_encoded
      conn.request :retry, max: 3, exceptions: [Errno::ECONNRESET, Faraday::ConnectionFailed,  Errno::ETIMEDOUT, Faraday::TimeoutError, Faraday::RetriableResponse]
      conn.adapter :excon, persistent: true, thread_safe_sockets: true
      # conn.adapter :net_http_persistent, pool_size: pool_size do |http|
      #   # yields Net::HTTP::Persistent
      #   http.idle_timeout = 120
      #   http.read_timeout = 180
      # end
    end
  end
end

Azure::Storage::Common::Client.send :include, AzureStorageCommonClientOverride
