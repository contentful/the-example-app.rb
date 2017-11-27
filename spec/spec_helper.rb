require 'simplecov'
SimpleCov.start

require 'dotenv/load'

require 'rspec'
require 'rack/test'
require 'capybara'
require 'capybara/dsl'

Dir[File.join(File.dirname(__FILE__), '..', '**', '*.rb')].each { |f| require f unless f.include?('_spec.rb') }

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
