require './routes/base'

module Routes
  class Index < Base
    get '/' do
      wrap_errors do
        landing_page = contentful.landing_page('home', api_id, locale.code)
        return not_found_error if landing_page.nil?

        attach_entry_state(landing_page) if attach_entry_state?

        render_with_globals :landingPage, locals: {
          landing_page: landing_page,
          breadcrumbs: Breadcrumbs.refine(raw_breadcrumbs, landing_page)
        }
      end
    end
  end
end
