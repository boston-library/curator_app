# frozen_string_literal: true

require 'azure/storage/blob'

# NOTE: this override is to prevent frequent Faraday::ConnectionFailed Connection Reset by peer error.
# Increased pool size. made agents a threadsafe hash instead of a base one. removed redundant reuse_agent! method in favor of
# perfomring operation in agents method. Try Using clear method  first instead of just setting agents instance variable to nil.
module AzureStorageCommonClientOverride
  def agents(uri)
    @agents ||= Concurrent::Map.new

    uri = URI(uri) unless uri.is_a? URI
    key = uri.host

    @agents.compute_if_absent(key) { build_http(uri) }

    @agents.compute_if_present(key) do |agent|
      agent.params.clear
      agent.headers.clear
      agent
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
    thread_size = ENV.fetch('RAILS_MAX_THREADS') { 5 }.to_i * 2 # Add an offset so the pool won't get full
    pool_size = thread_size * total_workers
    pool_size = 24 if pool_size < 24

    Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
      conn.use FaradayMiddleware::FollowRedirects
      conn.use Faraday::Request::UrlEncoded
      conn.adapter :net_http_persistent, pool_size: pool_size do |http|
        http.idle_timeout = 120
        http.read_timeout = 540
        http.socket_options << [Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1]
      end
    end
  end
end

Azure::Storage::Common::Client.send :include, AzureStorageCommonClientOverride
