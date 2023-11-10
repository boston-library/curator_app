# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0.6'

gem 'curator', github: 'boston-library/curator'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.7', '< 7'
# Use Puma as the app server
gem 'alba', '~> 2.2', '< 2.3'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 6.3'
gem 'oj', '~> 3.15'
gem 'sidekiq', '~> 7.1'
gem 'connection_pool', '~> 2.4'
gem 'faraday', '~> 1.10', '< 2'
gem 'faraday_middleware','~> 1.0'
gem 'net-http-persistent', '>= 4'
# gem 'typhoeus', '~> 1.4'
gem 'azure-storage-blob', '>= 2', require: false
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.8', '< 5'
gem 'rack-cors', '~> 1.1'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible

# NOTE these are required for 'Analyze Jobs' for active storage
gem 'image_processing', '~> 1.12'
gem 'mini_magick', '~> 4.11'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capistrano', '~> 3.17', require: false
  gem 'capistrano3-puma'
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rvm'
  gem 'pry', '~> 0.13.1'
  gem 'pry-rails'
  gem 'awesome_print', '~> 1.9'
  gem 'solr_wrapper', '~> 4'
  gem 'dotenv-rails', '~> 2.8', require: 'dotenv/rails-now'
  gem 'factory_bot_rails', '~> 6.2'
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'spring', '~> 2.1'
end

gem 'sd_notify', group: [:production, :staging]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
