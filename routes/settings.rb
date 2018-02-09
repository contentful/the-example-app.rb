require './routes/base'

module Routes
  class Settings < Base
    get '/settings' do
      wrap_errors do
        # By default this should be empty, but if redirected to /settings
        # when wrong credentials where entered in the query string, this check is
        # required in order to get the proper error messages in the inputs.
        errors = check_errors(
          session[:space_id] || ENV['CONTENTFUL_SPACE_ID'],
          session[:delivery_token] || ENV['CONTENTFUL_DELIVERY_TOKEN'],
          session[:preview_token] || ENV['CONTENTFUL_PREVIEW_TOKEN']
        )

        space = errors.empty? ? contentful.space(api_id) : nil
        render_with_globals :settings, locals: {
          title: I18n.translate('settingsLabel', locale.code),
          errors: errors,
          has_errors: !errors.empty?,
          success: false,
          space: space,
          is_using_custom_credentials: custom_credentials?,
          host: request.host_with_port
        }
      end
    end

    post '/settings' do
      wrap_errors do
        space_id = params['spaceId']
        delivery_token = params['deliveryToken']
        preview_token = params['previewToken']
        editorial_features = !!params['editorialFeatures']

        errors = check_errors(space_id, delivery_token, preview_token)

        if errors.empty?
          session[:space_id] = space_id
          session[:delivery_token] = delivery_token
          session[:preview_token] = preview_token
          session[:editorial_features] = editorial_features
        end

        space = errors.empty? ? contentful.space(api_id) : nil
        status errors.empty? ? 201 : 409
        render_with_globals :settings, locals: {
          title: I18n.translate('settingsLabel', locale.code),
          errors: errors,
          has_errors: !errors.empty?,
          success: errors.empty?,
          space: space,
          is_using_custom_credentials: custom_credentials?,
          host: request.host_with_port
        }
      end
    end

    post '/settings/reset' do
      wrap_errors do
        session[:space_id] = nil
        session[:delivery_token] = nil
        session[:preview_token] = nil
        session[:editorial_features] = false

        space = contentful.space(api_id)
        status 201
        render_with_globals :settings, locals: {
          title: I18n.translate('settingsLabel', locale.code),
          errors: [],
          has_errors: false,
          success: true,
          space: space,
          is_using_custom_credentials: custom_credentials?,
          host: request.host_with_port
        }
      end
    end
  end
end
