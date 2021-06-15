# frozen_string_literal: true

Curator.config do |config|
  if %w(staging production).member?(Rails.env)
    config.ark_manager_api_url = Rails.application.credentials.dig(:ark_manager_api_url)
    config.authority_api_url = Rails.application.credentials.dig(:authority_api_url)
    config.solr_url = Rails.application.credentials.dig(:solr_url)
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
    config.default_ark_params = {
      namespace_ark: ENV['ARK_NAMESPACE'],
      namespace_id: ENV['ARK_MANAGER_DEFAULT_NAMESPACE'],
      oai_namespace_id: ENV['ARK_MANAGER_OAI_NAMESPACE'],
      url_base: ENV['ARK_MANAGER_DEFAULT_BASE_URL']
    }
  end
end
