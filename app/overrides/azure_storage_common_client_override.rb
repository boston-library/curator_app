# frozen_string_literal: true

require 'azure/storage/blob'

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
    Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
      conn.use FaradayMiddleware::FollowRedirects
      conn.adapter :http
    end
  end
end

Azure::Storage::Common::Client.send :include, AzureStorageCommonClientOverride
