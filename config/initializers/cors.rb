# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors, logger: (-> { Rails.logger }) do
  allow do
    origins /localhost:300[0-2]/, /127\.0\.0\.1:300[0-2]/, 'https://search-dc3dev.bpl.org'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :head],
      max_age: 0

    resource '*',
     :headers => :any,
     :methods => [:get, :options, :head],
     :max_age => 0
  end
end
