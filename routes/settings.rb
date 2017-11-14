require 'sinatra/base'

module Routes
  class Settings < Sinatra::Base
    enable :sessions

    get '/settings' do
    end

    post '/settings' do
    end
  end
end
