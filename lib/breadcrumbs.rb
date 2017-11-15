require './i18n/i18n'

module Breadcrumbs
  # Creates breadcrumbs from request path, also replaces labels with translations when available
  #
  # @param request [Sinatra::Request]
  # @param locale [Contentful::Locale]
  #
  # @return [Array]
  def self.breadcrumbs(request, locale)
    crumbs = []

    crumbs << {
      url: '/',
      label: I18n.translate('homeLabel', locale.code)
    }

    parts = request.path.split('/')[1..-1] || []

    parts.each_with_index do |part, index|
      label = part.tr('-', ' ')
      label = I18n.translate("#{label}Label", locale.code) if I18n.translation_avaliable("#{label}Label", locale.code)

      path = parts[0..index].join('/')
      crumbs << {
        url: "/#{path}",
        label: label
      }
    end

    crumbs
  end

  # Refines breadcrumbs with entry titles if available
  #
  # @param crumbs [Array]
  # @param resource [Contentful::Entry]
  #
  # @return [Array]
  def self.refine(crumbs, resource)
    crumbs.map do |crumb|
      crumb[:label] = resource.title if crumb[:label].tr(' ', '-') == resource.slug
      crumb
    end
  end
end
