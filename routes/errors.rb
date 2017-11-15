require './routes/base'

module Routes
  module Errors
    def wrap_errors
      yield if block_given?
    rescue ::Contentful::Error => e
      return contentful_error(e)
    rescue ::Exception => e
      generic_error(e)
    end

    def not_found_error(error_message = nil)
      err = env['sinatra.error'] || error_message
      render_with_globals :error, locals: {
        error: err,
        stacktrace: caller.join("\n"),
        status: 404,
        environment: ENV['APP_ENV']
      }
    end

    def contentful_error(error)
      render_with_globals :error, locals: {
        error: error,
        stacktrace: error.backtrace.join("\n"),
        status: error.response.raw.code,
        environment: ENV['APP_ENV']
      }
    end

    def generic_error(error)
      render_with_globals :error, locals: {
        error: error,
        stacktrace: caller.join("\n"),
        status: 500,
        environment: ENV['APP_ENV']
      }
    end
  end
end
