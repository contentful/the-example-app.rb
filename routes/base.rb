require 'sinatra/base'
require './services/contentful'
require './lib/breadcrumbs'
require './lib/entry_state'
require './routes/errors'

# Base class for route middleware
module Routes
  class Base < Sinatra::Base
    include Errors
    include EntryState

    set :views, File.join(Dir.pwd, 'views')

    DEFAULT_API = 'cda'.freeze
    DEFAULT_LOCALE_CODE = 'en-US'.freeze
    DEFAULT_LOCALE = ::Contentful::Locale.new(
      'code' => DEFAULT_LOCALE_CODE,
      'name' => 'U.S. English',
      'default' => true
    )

    # If configuration is sent on the parameters, save it in the session
    before do
      session[:space_id] = params['space_id'] if params.key?('space_id')
      session[:delivery_token] = params['delivery_token'] if params.key?('delivery_token')
      session[:preview_token] = params['preview_token'] if params.key?('preview_token')
      session[:editorial_features] = true if params.key?('enable_editorial_features')
    end

    # Wrapper for the Contentful service
    def contentful
      Services::Contentful.instance(
        session[:space_id] || ENV['CONTENTFUL_SPACE_ID'],
        session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN'],
        session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN']
      )
    end

    # Gets the selected API
    def api_id
      @api_id = params['api'] || DEFAULT_API
    end

    # Gets the current API data
    def current_api
      {
        cda: {
          label: I18n.translate('contentDeliveryApiLabel', locale.code),
          id: 'cda'
        },
        cpa: {
          label: I18n.translate('contentPreviewApiLabel', locale.code),
          id: 'cpa'
        }
      }[api_id.to_sym]
    end

    # Gets the selected locale
    def locale
      @locale ||= locales.detect { |locale| locale.code == (params['locale'] || DEFAULT_LOCALE_CODE) }
    rescue
      DEFAULT_LOCALE
    end

    # Gets all the available locales for the given space
    def locales
      @locales ||= contentful.space(api_id).locales
    rescue ::Contentful::Error
      [DEFAULT_LOCALE]
    end

    # Wrapper for the breadcrumb helper
    def raw_breadcrumbs
      Breadcrumbs.breadcrumbs(request, locale)
    end

    # Strips session parameters from query string
    def query_string
      request.query_string.split('&').reject do |part|
        key = part.split('=').first

        %w(space_id delivery_token preview_token enable_editorial_features).include?(key)
      end.join('&')
    end

    helpers do
      # Wrapper for template rendering with all shared global state
      def render_with_globals(template, locals: {})
        globals = {
          title: nil,
          current_locale: locale,
          current_api: current_api,
          current_path: request.path,
          query_string: query_string.empty? ? '' : "?#{query_string}",
          breadcrumbs: raw_breadcrumbs,
          editorial_features: session[:editorial_features],
          space_id: session[:space_id] || ENV['CONTENTFUL_SPACE_ID'],
          delivery_token: session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN'],
          preview_token: session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN']
        }

        slim template, locals: globals.merge(locals)
      end

      # Helper for titles
      def format_meta_title(title, locale)
        return I18n.translate('defaultTitle', locale) unless title
        "#{title.capitalize} - #{I18n.translate('defaultTitle', locale)}"
      end


      # Checks if user is using session or environment credentials
      def custom_credentials?
        session_space_id = session[:space_id]
        session_delivery_token = session[:delivery_token]
        session_preview_token = session[:preview_token]

        !session_space_id.nil? &&
          session_space_id != ENV['CONTENTFUL_SPACE_ID'] &&
          !session_delivery_token.nil? &&
          session_delivery_token != ENV['CONTENTFUL_DELIVERY_TOKEN'] &&
          !session_preview_token.nil? &&
          session_preview_token != ENV['CONTENTFUL_PREVIEW_TOKEN']
      end


      # Helper for parameterized url
      def parameterized_url
        return "" unless custom_credentials?

        query = {
          space_id: session[:space_id],
          delivery_token: session[:delivery_token],
          preview_token: session[:preview_token],
          api_id: api_id
        }.collect { |key, value| "#{key}=#{value}"}.join("&")

        editorial_features_query = session[:enable_editorial_features] ? "&enable_editorial_features" : ""

        return "?#{query}#{editorial_features_query}"

      end
    end
  end
end
