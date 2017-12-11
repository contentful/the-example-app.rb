require './routes/base'

module Routes
  class Settings < Base
    enable :sessions

    get '/settings' do
      wrap_errors do
        space = contentful.space(api_id)
        render_with_globals :settings, locals: {
          title: I18n.translate('settingsLabel', locale.code),
          errors: {},
          has_errors: false,
          success: true,
          space: space,
          is_using_custom_credentials: custom_credentials?
        }
      end
    end

    post '/settings' do
      wrap_errors do
        errors = {}
        space_id = params['spaceId']
        delivery_token = params['deliveryToken']
        preview_token = params['previewToken']
        editorial_features = !!params['editorialFeatures']

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

        if errors.empty?
          session[:space_id] = space_id
          session[:delivery_token] = delivery_token
          session[:preview_token] = preview_token
          session[:editorial_features] = editorial_features
        end

        space = contentful.space(api_id)
        status errors.empty? ? 201 : 409
        render_with_globals :settings, locals: {
          title: I18n.translate('settingsLabel', locale.code),
          errors: errors,
          has_errors: !errors.empty?,
          success: errors.empty?,
          space: space,
          is_using_custom_credentials: custom_credentials?
        }
      end
    end

    post '/settings/reset' do
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
        is_using_custom_credentials: custom_credentials?
      }
    end

    # Helper for checking space/token combinations
    def validate_space_token_combination(errors, space_id, access_token, is_preview = false)
      Services::Contentful.create_client(space_id, access_token, is_preview)
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
  end
end
