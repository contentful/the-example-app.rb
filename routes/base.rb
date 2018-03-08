require 'sinatra/base'
require './services/contentful'
require './lib/breadcrumbs'
require './lib/entry_state'
require './routes/errors'

# Base class for route middleware
module Routes
  class Base < Sinatra::Base
    TWO_DAYS_IN_SECONDS = 172_800

    include Errors
    include EntryState

    enable :sessions
    set :session_secret, ENV['SESSION_SECRET']
    # Enable Sinatra session after SslEnforcer
    use Rack::Session::Cookie,
        key: 'rack.session',
        path: '/',
        expire_after: TWO_DAYS_IN_SECONDS,
        secret: settings.session_secret

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
      session[:editorial_features] = params.delete('editorial_features') == 'enabled'

      if changes_credentials? && !session[:has_errors]
        errors = check_errors(
          params['space_id'] || ENV['CONTENTFUL_SPACE_ID'],
          params['delivery_token'] || ENV['CONTENTFUL_DELIVERY_TOKEN'],
          params['preview_token'] || ENV['CONTENTFUL_PREVIEW_TOKEN']
        )

        session[:has_errors] = !errors.empty?
        unless errors.empty?
          session[:last_valid_space_id] = space_id
          session[:last_valid_delivery_token] = delivery_token
          session[:last_valid_preview_token] = preview_token
        end
      end

      %w(space_id delivery_token preview_token).each do |key|
        session[key.to_sym] = params[key] if params.key?(key)
      end
    end

    # Wrapper for the Contentful service
    def contentful
      Services::Contentful.instance(
        space_id,
        delivery_token,
        preview_token,
        ENV['CONTENTFUL_HOST']
      )
    end

    # Gets the current space ID
    def space_id
      session[:space_id] || ENV['CONTENTFUL_SPACE_ID']
    end

    # Gets the current delivery token
    def delivery_token
      session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN']
    end

    # Gets the current preview token
    def preview_token
      session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN']
    end

    # Gets the selected API
    def api_id
      @api_id = params['api'] || DEFAULT_API
    end

    # Gets the current API data
    def current_api
      api_data = {
        cda: {
          label: I18n.translate('contentDeliveryApiLabel', locale.code),
          id: 'cda'
        },
        cpa: {
          label: I18n.translate('contentPreviewApiLabel', locale.code),
          id: 'cpa'
        }
      }

      api_data.key?(api_id.to_sym) ? api_data[api_id.to_sym] : api_data[DEFAULT_API.to_sym]
    end

    # Gets the selected locale
    def locale
      @locale ||= locales.detect { |locale| locale.code == (params['locale'] || DEFAULT_LOCALE_CODE) }
      return @locale.nil? ? DEFAULT_LOCALE : @locale
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
          is_using_custom_credentials: custom_credentials?,
          space_id: space_id,
          delivery_token: delivery_token,
          preview_token: preview_token
        }

        slim template, locals: globals.merge(locals)
      end

      # Helper for titles
      def format_meta_title(title, locale)
        return I18n.translate('defaultTitle', locale) unless title
        "#{title.capitalize} — #{I18n.translate('defaultTitle', locale)}"
      end

      # Helper for parameterized url
      def parameterized_url
        return "" unless custom_credentials?

        query = {
          space_id: space_id,
          delivery_token: delivery_token,
          preview_token: preview_token,
          api_id: api_id
        }.collect { |key, value| "#{key}=#{value}"}.join("&")

        editorial_features_query = session[:editorial_features] ? "&editorial_features=enabled" : ""

        "?#{query}#{editorial_features_query}"
      end
    end

    # Checks if user is using session or environment credentials
    def custom_credentials?
      session_space_id = space_id
      session_delivery_token = delivery_token
      session_preview_token = preview_token

      (!session_space_id.nil? &&
        session_space_id != ENV['CONTENTFUL_SPACE_ID']) ||
        (!session_delivery_token.nil? &&
        session_delivery_token != ENV['CONTENTFUL_DELIVERY_TOKEN']) ||
        (!session_preview_token.nil? &&
        session_preview_token != ENV['CONTENTFUL_PREVIEW_TOKEN'])
    end

    # Check if user is defining different credentials than currently stored ones
    def changes_credentials?
      current_space_id = space_id
      current_delivery_token = delivery_token
      current_preview_token = preview_token

      attempted_space_id = params['space_id']
      attempted_delivery_token = params['delivery_token']
      attempted_preview_token = params['preview_token']

      (!attempted_space_id.nil? && current_space_id != attempted_space_id) ||
        (!attempted_delivery_token.nil? && current_delivery_token != attempted_delivery_token) ||
        (!attempted_preview_token.nil? && current_preview_token != attempted_preview_token)
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
