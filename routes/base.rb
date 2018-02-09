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

    enable :sessions

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
      if changes_credentials? && !session[:has_errors]
        %w(space_id delivery_token preview_token).each do |key|
          session[key.to_sym] = params.delete(key) if params.key?(key)
        end
        session[:editorial_features] = params['editorial_features'] == 'enabled' if params.key?('editorial_features')

        if custom_credentials?
          errors = check_errors(
            session[:space_id],
            session[:delivery_token],
            session[:preview_token]
          )

          session[:has_errors] = !errors.empty?
        end
      end
    end

    # Wrapper for the Contentful service
    def contentful
      Services::Contentful.instance(
        session[:space_id] || ENV['CONTENTFUL_SPACE_ID'],
        session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN'],
        session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN'],
        ENV['CONTENTFUL_HOST']
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

        %w(space_id delivery_token preview_token editorial_features).include?(key)
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

        (!session_space_id.nil? &&
          session_space_id != ENV['CONTENTFUL_SPACE_ID']) ||
          (!session_delivery_token.nil? &&
          session_delivery_token != ENV['CONTENTFUL_DELIVERY_TOKEN']) ||
          (!session_preview_token.nil? &&
          session_preview_token != ENV['CONTENTFUL_PREVIEW_TOKEN'])
      end

      # Check if user is defining different credentials than currently stored ones
      def changes_credentials?
        current_space_id = session[:space_id] || ENV['CONTENTFUL_SPACE_ID']
        current_delivery_token = session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN']
        current_preview_token = session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN']

        attempted_space_id = params['space_id']
        attempted_delivery_token = params['delivery_token']
        attempted_preview_token = params['preview_token']

        (!attempted_space_id.nil? && current_space_id != attempted_space_id) ||
          (!attempted_delivery_token.nil? && current_delivery_token != attempted_delivery_token) ||
          (!attempted_preview_token.nil? && current_preview_token != attempted_preview_token)
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

        editorial_features_query = session[:editorial_features] ? "&editorial_features=enabled" : ""

        "?#{query}#{editorial_features_query}"
      end
    end

    # Helper for checking all errors
    def check_errors(space_id, delivery_token, preview_token)
      errors = {}
      if space_id.nil? || space_id.empty?
        errors[:spaceId] ||= []
        errors[:spaceId] << I18n.translate('fieldIsRequiredLabel', locale.code)
      end

      if delivery_token.nil? || delivery_token.empty?
        errors[:deliveryToken] ||= []
        errors[:deliveryToken] << I18n.translate('fieldIsRequiredLabel', locale.code)
      end

      if preview_token.nil? || preview_token.empty?
        errors[:previewToken] ||= []
        errors[:previewToken] << I18n.translate('fieldIsRequiredLabel', locale.code)
      end

      if errors.empty?
        validate_space_token_combination(errors, space_id, delivery_token)
        validate_space_token_combination(errors, space_id, preview_token, true)
      end

      errors
    end

    # Helper for checking space/token combinations
    def validate_space_token_combination(errors, space_id, access_token, is_preview = false)
      Services::Contentful.create_client(space_id, access_token, is_preview, ENV['CONTENTFUL_HOST'])
    rescue ::Contentful::Error => e
      token_field = is_preview ? :previewToken : :deliveryToken

      case e.response.raw.code
      when 401
        error_label = is_preview ? 'previewKeyInvalidLabel' : 'deliveryKeyInvalidLabel'

        errors[token_field] ||= []
        errors[token_field] << I18n.translate(error_label, locale.code)
      when 404
        message = I18n.translate('spaceOrTokenInvalid', locale.code)
        errors[:spaceId] ||= []
        errors[:spaceId] << message unless errors[:spaceId].include?(message)
      else
        errors[token_field] ||= []
        errors[token_field] << "#{I18n.translate('somethingWentWrongLabel', locale.code)}: #{e.message}"
      end
    end
  end
end
