# frozen_string_literal: true

Curator.config do |config|
  if %w(staging production).member?(Rails.env)
    config.ark_manager_api_url = Rails.application.credentials[:ark_manager_api_url]
    config.authority_api_url = Rails.application.credentials[:authority_api_url]
    config.solr_url = Rails.application.credentials[:solr_url]
    config.avi_processor_api_url = Rails.application.credentials[:avi_processor_api_url]
    config.ingest_source_directory = Rails.application.credentials[:ingest_source_directory]
    config.fedora_credentials = {
      fedora_username: Rails.application.credentials.dig(:fedora, :username),
      fedora_password: Rails.application.credentials.dig(:fedora, :password)
    }
    config.default_ark_params = {
      namespace_ark: Rails.application.credentials.dig(:ark, :namespace_ark),
      namespace_id: Rails.application.credentials.dig(:ark, :namespace_id),
      oai_namespace_id: Rails.application.credentials.dig(:ark, :oai_namespace_id),
      url_base: Rails.application.credentials.dig(:ark, :url_base)
    }
  else
    config.ark_manager_api_url = ENV['ARK_MANAGER_API_URL']
    config.authority_api_url = ENV['AUTHORITY_API_URL']
    config.solr_url = ENV['CURATOR_SOLR_URL']
    config.avi_processor_api_url = ENV['ARK_MANAGER_API_URL']
    config.ingest_source_directory = ENV['INGEST_SOURCE_DIRECTORY']
    config.fedora_credentials = {
      fedora_username: ENV['FEDORA_USERNAME'],
      fedora_password: ENV['FEDORA_PASSWORD']
    }
    config.default_ark_params = {
      namespace_ark: ENV['ARK_NAMESPACE'],
      namespace_id: ENV['ARK_MANAGER_DEFAULT_NAMESPACE'],
      oai_namespace_id: ENV['ARK_MANAGER_OAI_NAMESPACE'],
      url_base: ENV['ARK_MANAGER_DEFAULT_BASE_URL']
    }
  end

  config.default_remote_service_timeout_opts = {
    connect: 15,
    read: 600,
    write: 120,
    keep_alive: 120
  }

  config.default_remote_service_pool_opts = {
      size: ENV.fetch('RAILS_MAX_THREADS') { 5 }.to_i + 2,
      timeout: 15
  }
end
