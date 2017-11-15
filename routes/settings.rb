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
          success: false,
          space: space
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
        render_with_globals :settings, locals: {
          title: I18n.translate('settingsLabel', locale.code),
          errors: errors,
          has_errors: !errors.empty?,
          success: errors.empty?,
          space: space
        }
      end
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
  end
end
