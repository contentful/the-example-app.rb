require './i18n/i18n'

module Breadcrumbs
  def self.breadcrumbs(request, locale)
    crumbs = []

    crumbs << {
      url: "/",
      label: I18n.translate('homeLabel', locale.code)
    }

    parts = request.path.split('/')[1..-1] || []

    parts.each_with_index do |part, index|
      label = part.gsub('-', ' ')
      label = I18n.translate("#{label}Label", locale.code) if I18n.translation_avaliable("#{label}Label", locale.code)

      path = parts[0..index].join('/')
      crumbs << {
        url: "/#{path}",
        label: label
      }
    end

    crumbs
  end

  def self.refine(crumbs, resource)
    crumbs.map do |crumb|
      crumb[:label] = resource.title if crumb[:label].gsub(' ', '-') == resource.slug
      crumb
    end
  end
end
