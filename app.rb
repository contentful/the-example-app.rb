require 'slim'
require 'commonmarker'
require 'dotenv/load'
require 'sinatra/base'
require 'rack/ssl-enforcer'

# Routes
require './routes/index'
require './routes/errors'
require './routes/courses'
require './routes/imprint'
require './routes/settings'

# Helpers
require './i18n/i18n'

class ExampleApp < Routes::Base
  DEFAULT_PORT = 3_000

  # Global options
  set :public_folder, File.join(Dir.pwd, 'public')
  set :raise_errors, true
  set :show_exceptions, :after_handler

  I18n.initialize_translations

  # Middleware
  use Rack::SslEnforcer,
      only_environmnets: ['production', 'staging'],
      except_hosts: 'localhost',
      redirect_html: false

  # Routes
  use Routes::Index
  use Routes::Courses
  use Routes::Imprint
  use Routes::Settings

  # Generic error handlers
  not_found do
    not_found_error(nil, false)
  end

  error 500 do
    generic_error(env['sinatra.error'])
  end
end
