require 'slim'
require 'commonmarker'
require 'dotenv/load'
require 'sinatra/base'
require 'rack-livereload'
require 'rack/ssl-enforcer'

# Routes
require './routes/index'
require './routes/errors'
require './routes/courses'
require './routes/imprint'
require './routes/settings'

# Helpers
require './i18n/i18n'

class ExampleApp < Sinatra::Base
  TWO_DAYS_IN_SECONDS = 172_800
  DEFAULT_PORT = 3_000

  # Global options
  set :public_folder, File.join(Dir.pwd, 'public')
  set :session_secret, ENV['SESSION_SECRET']
  set :raise_errors, true
  set :show_exceptions, :after_handler

  I18n.initialize_translations

  # Middleware
  use Rack::LiveReload if settings.development?
  use Rack::SslEnforcer,
      only_environmnets: ['production', 'staging'],
      except_hosts: 'localhost',
      redirect_html: false

  # Enable Sinatra session after SslEnforcer
  use Rack::Session::Cookie,
      key: '_rack_session',
      path: '/',
      expire_after: TWO_DAYS_IN_SECONDS,
      secret: settings.session_secret

  # Routes
  use Routes::Index
  use Routes::Courses
  use Routes::Imprint
  use Routes::Settings
end
