require './routes/base'

module Routes
  class Index < Base
    get '/' do
      landing_page = contentful.landing_page('home', api_id, locale.code)
      render_with_globals :landingPage, locals: {
        landing_page: landing_page,
        breadcrumbs: Breadcrumbs.refine(raw_breadcrumbs, landing_page)
      }
    end
  end
end
