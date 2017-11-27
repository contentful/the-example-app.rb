require 'simplecov'
SimpleCov.start

require 'dotenv/load'

require 'rspec'
require 'rack/test'
require 'capybara'
require 'capybara/dsl'

['lib', 'I18n', 'routes', 'services'].each do |dir|
  Dir[File.join(File.dirname(__FILE__), '..', dir, '*.rb')].each do |f|
    require f
  end
end

require File.join(File.dirname(__FILE__), '..', 'app.rb')

Capybara.app = ExampleApp

BASE_ROUTE = 'www.example.org'

def route(path, secure = true)
  "http#{secure ? 's' : ''}://#{BASE_ROUTE}#{path}"
end

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.include Capybara::DSL
  config.include Rack::Test::Methods
end
