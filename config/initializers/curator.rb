# frozen_string_literal: true

Curator.config do |config|
  config.ark_manager_api_url = Rails.application.credentials.dig(:ark_manager_api_url)
  config.authority_api_url = Rails.application.credentials.dig(:authority_api_url)
  config.default_ark_params = {
    namespace_ark: Rails.application.credentials.dig(:ark, :namespace_ark),
    namespace_id: Rails.application.credentials.dig(:ark, :namespace_id),
    oai_namespace_id: Rails.application.credentials.dig(:ark, :oai_namespace_id),
    url_base: Rails.application.credentials.dig(:ark, :url_base)
  }
  config.solr_url = Rails.application.credentials.dig(:solr_url)
end
