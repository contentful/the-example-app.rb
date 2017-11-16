require 'rspec'
require 'rack/test'

Dir[File.join(File.dirname(__FILE__), '..', '**', '*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
