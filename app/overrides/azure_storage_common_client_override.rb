# frozen_string_literal: true

require 'azure/storage/blob'

# NOTE: this override is to prevent frequent Faraday::ConnectionFailed Connection Reset by peer error.
# Increased pool size. made agents a threadsafe hash instead of a base one. removed redundant reuse_agent! method in favor of
# perfomring operation in agents method. Try Using clear method  first instead of just setting agents instance variable to nil.
module AzureStorageCommonClientOverride
  def agents(uri)
    uri = URI(uri) unless uri.is_a? URI
    key = uri.host

    @agents ||= Concurrent::Hash.new
    if @agents[key].present?
      @agents[key].params.clear
      @agents[key].headers.clear
    else
      @agents[key] = build_http(uri)
    end
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

    total_workers = ENV.fetch('WEB_CONCURRENCY') { 2 }.to_i
    pool_size = ENV.fetch('RAILS_MAX_THREADS') { 5 }.to_i * total_workers
    pool_size = 10 if pool_size < 10
    # request_options = { read_timeout: 240, write_timeout: 240, open_timeout: 15 }
    Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
      conn.use FaradayMiddleware::FollowRedirects
      conn.use Faraday::Request::Multipart
      conn.use Faraday::Request::UrlEncoded
      conn.adapter :net_http_persistent, pool_size: pool_size do |http|
        http.idle_timeout = 120
        http.read_timeout = 240
        http.write_timeout = 240
        http.open_timeout = 15
      end
    end
  end
end

Azure::Storage::Common::Client.send :include, AzureStorageCommonClientOverride
