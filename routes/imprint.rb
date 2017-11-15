require './routes/base'

module Routes
  class Imprint < Base
    get '/imprint' do
      wrap_errors do
        render_with_globals :imprint, locals: {
          title: I18n.translate('imprintLabel', locale.code)
        }
      end
    end
  end
end
