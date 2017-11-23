require 'simplecov'
SimpleCov.start

require 'rspec'
require 'rack/test'

Dir[File.join(File.dirname(__FILE__), '..', '**', '*.rb')].each { |f| require f unless f.include?('_spec.rb') }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
