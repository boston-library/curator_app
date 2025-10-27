# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.3.10'

gem 'curator', github: 'boston-library/curator'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.1.5'
# Use Puma as the app server
gem 'alba', '~> 3.9'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 6.6'
gem 'oj', '~> 3.16'
gem 'sidekiq', '~> 7.3.9'
gem 'concurrent-ruby', '~> 1.3'
gem 'connection_pool', '~> 2.5'
gem 'faraday', '~> 1.10', '< 2'
gem 'faraday_middleware','~> 1.0'
gem 'net-http-persistent', '>= 4'
# gem 'typhoeus', '~> 1.4'
gem 'azure-storage-blob', '>= 2', require: false
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5'
gem 'rack-cors', '~> 1.1'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible

# NOTE these are required for 'Analyze Jobs' for active storage
gem 'image_processing', '~> 1.14'
gem 'mini_magick', '~> 5.3'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'capistrano', '~> 3.19.2', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rvm'
  gem 'debug', platforms: %i[mri windows]
  gem 'solr_wrapper', '~> 4.2'
  gem 'dotenv-rails', '~> 2.8', require: 'dotenv/rails-now'
  gem 'factory_bot_rails', '~> 6.2'
end

group :development do
  gem 'listen', '~> 3.3'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]
