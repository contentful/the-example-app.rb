require 'sinatra/base'
require './services/contentful'
require './lib/breadcrumbs'
require './lib/entry_state'
require './routes/errors'

module Routes
  class Base < Sinatra::Base
    include Errors
    include EntryState

    set :views, File.join(Dir.pwd, 'views')

    DEFAULT_API = 'cda'.freeze
    DEFAULT_LOCALE = ::Contentful::Locale.new({
      'code' => 'en-US',
      'name' => 'US English',
      'default' => true
    })

    def contentful
      Services::Contentful.instance(
        session[:space_id] || ENV['CONTENTFUL_SPACE_ID'],
        session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN'],
        session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN']
      )
    end

    def api_id
      @api_id = params['api'] || DEFAULT_API
    end

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

    def locale
      @locale = locales.detect { |locale| locale.code == params['locale'] }
    rescue ::Contentful::Error
      DEFAULT_LOCALE
    end

    def locales
      @locales ||= contentful.space(api_id).locales
    rescue ::Contentful::Error
      [ DEFAULT_LOCALE ]
    end

    def raw_breadcrumbs
      Breadcrumbs.breadcrumbs(request, locale)
    end

    helpers do
      def render_with_globals(template, locals: {})
        globals = {
          title: nil,
          current_locale: locale,
          current_api: current_api,
          current_path: request.path,
          query_string: request.query_string ? "?#{request.query_string}" : '',
          breadcrumbs: raw_breadcrumbs,
          editorial_features: session[:editorial_features],
          space_id: session[:space_id] || ENV['CONTENTFUL_SPACE_ID']
        }

        slim template, locals: globals.merge(locals)
      end

      def format_meta_title(title, locale)
        return I18n.translate('defaultTitle', locale) unless title
        "#{title.capitalize} - #{I18n.translate('defaultTitle', locale)}"
      end
    end
  end
end
