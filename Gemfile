source 'https://rubygems.org'

ruby '2.4.1'

# Task manager
gem 'foreman'

# Web framework
gem 'sinatra'

# SSL enforcer
gem 'rack-ssl-enforcer'

# Live-reload
gem 'rack-livereload'

# Templating language
gem 'slim'

# Markdown engine
gem 'kramdown'

# Configuration management
gem 'dotenv'

# Contentful Delivery SDK
gem 'contentful'

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
end
