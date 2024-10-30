# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CuratorApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.api_only = true
    config.eager_load_paths += %W(#{config.root}/lib)

    config.action_dispatch.default_headers['X-Frame-Options'] = 'DENY'
    # nil sets these to use the default queue
    config.active_storage.queues.analysis   = nil       # defaults to "active_storage_analysis"
    config.active_storage.queues.purge      = nil       # defaults to "active_storage_purge"
    config.active_storage.queues.mirror     = nil       # defaults to "active_storage_mirror

    config.session_store :cookie_store, key: '_interslice_session'
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options
  end
end
