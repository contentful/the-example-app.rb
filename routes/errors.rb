require './routes/base'

module Routes
  module Errors
    # Wrapper for displaying a custom error page
    def wrap_errors
      if session[:has_errors]
        session.delete(:has_errors)
        return redirect('/settings')
      end
      yield if block_given?
    rescue ::Contentful::Error => e
      return contentful_error(e)
    rescue ::StandardError => e
      generic_error(e)
    end

    # Helper for displaying 404 when no entries are found
    def not_found_error(error_message = nil, contentful_resource=true)
      err = error_message || env['sinatra.error']
      status 404
      render_with_globals :error, locals: {
        error: err,
        contentful_resource: contentful_resource,
        stacktrace: caller.join("\n"),
        status: 404,
        environment: ENV['APP_ENV']
      }
    end

    # Helper for displaying errors coming from the Contentful API
    def contentful_error(error)
      status_code = error.response.raw.code
      status status_code
      render_with_globals :error, locals: {
        error: error,
        contentful_resource: true,
        stacktrace: error.backtrace.join("\n"),
        status: status_code,
        environment: ENV['APP_ENV']
      }
    end

    # Helper for displaying server errors
    def generic_error(error)
      status 500
      render_with_globals :error, locals: {
        error: error,
        contentful_resource: false,
        stacktrace: caller.join("\n"),
        status: 500,
        environment: ENV['APP_ENV']
      }
    end
  end
end
