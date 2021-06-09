REDIS_SIDEKIQ_URL= ENV.fetch('CURATOR_APP_SIDEKIQ_REDIS_URL') { Rails.application.secrets.dig(:redis, :sidekiq_url) }

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_SIDEKIQ_URL }
end

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_SIDEKIQ_URL }
end
