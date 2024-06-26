# frozen_string_literal: true

REDIS_SIDEKIQ_URL= ENV.fetch('CURATOR_APP_SIDEKIQ_REDIS_URL') { Rails.application.credentials.dig(:redis, :sidekiq_url) }

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_SIDEKIQ_URL }
end

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_SIDEKIQ_URL }
  config.logger = Sidekiq::Logger.new($stdout)
  config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
end
