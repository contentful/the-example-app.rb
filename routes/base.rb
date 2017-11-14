require 'sinatra/base'
require './services/contentful'
require './lib/breadcrumbs'

module Routes
  class Base < Sinatra::Base
    set :views, File.join(Dir.pwd, 'views')

    DEFAULT_API = 'cda'.freeze

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
      @locale = locales.detect { |locale| locale.code == params['locale'] } || default_locale
    end

    def locales
      @locales ||= contentful.space(api_id).locales
    end

    def default_locale
      @default_locale ||= locales.detect { |locale| locale.default }
    end

    def raw_breadcrumbs
      Breadcrumbs.breadcrumbs(request, locale)
    end

    helpers do
      def render_with_globals(template, locals: {})
        globals = {
          current_locale: locale,
          current_api: current_api,
          current_path: request.path,
          query_string: request.query_string ? "?#{request.query_string}" : '',
          breadcrumbs: raw_breadcrumbs
        }

        slim template, locals: globals.merge(locals)
      end
    end
  end
end
