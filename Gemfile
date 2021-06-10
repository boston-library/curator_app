source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 2.6'

# gem 'curator', github: 'boston-library/curator'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.3', '>= 6.1.3.1', '< 6.2'
# Use Puma as the app server
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 5.3'
gem 'oj', '~> 3.11'
gem 'sidekiq', '~> 6.2'
gem 'connection_pool', '~> 2.2.5'
gem 'azure-storage-blob', '>= 1.1', require: false
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.2'
gem 'rack-cors', '~> 1.1'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible


group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry', '0.14'
  gem 'solr_wrapper', '>= 2.1', '< 3.0'
  gem 'dotenv-rails', '~> 2.7'
  gem 'factory_bot_rails', '~> 5.0'
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'spring', '~> 2.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
