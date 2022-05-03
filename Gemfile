source 'https://rubygems.org'

ruby '2.4.1'

# Task manager
gem 'foreman'

# Web framework
gem 'sinatra', '~> 2.2.0'

# SSL enforcer
gem 'rack-ssl-enforcer'

# Templating language
gem 'slim'

# Markdown engine
gem 'commonmarker'

# Configuration management
gem 'dotenv'

# Contentful Delivery SDK
gem 'contentful', '~> 2.6.0'

# Rake tasks
gem 'rake'

group :development do
  gem 'rerun'
end

group :development, :test do
  # Debugging
  gem 'pry'
  gem 'pry-remote'
end

group :test do
  # Testing
  gem 'rspec'
  gem 'rack-test', require: 'rack/test'
  gem 'guard'
  gem 'guard-rspec'
  gem 'simplecov'
  gem 'capybara', '~> 2.8'
end
