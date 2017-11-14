require 'contentful'

module Services
  class Contentful
    def self.instance(space_id, delivery_token, preview_token)
      @instance ||= nil

      # We create new client instances only if credentials changed or client wasn't instantiated before
      if (
        @instance.nil? || (
          @instance.space_id != space_id ||
          @instance.delivery_token != delivery_token ||
          @instance.preview_token != preview_token
        ))
        @instance = new(space_id, delivery_token, preview_token)
      end

      @instance
    end

    attr_reader :space_id, :delivery_token, :preview_token

    def client(api_id)
      api_id == 'cda' ? @delivery_client : @preview_client
    end

    def space(api_id)
      client(api_id).space
    end

    def courses(api_id = 'cda', locale = 'en-US', options = {})
      options = {
        content_type: 'course',
        locale: locale,
        order: '-sys.createdAt',
        include: 6
      }.merge(options)

      client(api_id).entries(options)
    end

    def course(slug, api_id = 'cda', locale = 'en-US')
      courses(api_id, locale, 'fields.slug' => slug)[0]
    end

    def courses_by_category(category_id, api_id = 'cda', locale = 'en-US')
      courses(api_id, locale, 'fields.categories.sys.id' => category_id)
    end

    def categories(api_id = 'cda', locale = 'en-US')
      client(api_id).entries(
        content_type: 'category',
        locale: locale,
      )
    end

    def landing_page(slug, api_id = 'cda', locale = 'en-US')
      client(api_id).entries(
        content_type: 'layout',
        locale: locale,
        include: 6,
        'fields.slug' => slug
      )[0]
    end

    def entry(entry_id, api_id)
      client(api_id).entry(entry_id)
    end

    private

    def initialize(space_id, delivery_token, preview_token)
      @space_id = space_id
      @delivery_token = delivery_token
      @preview_token = preview_token

      @delivery_client = create_client(@space_id, @delivery_token)
      @preview_client = create_client(@space_id, @preview_token, true)
    end

    def create_client(space_id, access_token, is_preview = false)
      options = {
        space: space_id,
        access_token: access_token,
        dynamic_entries: :auto,
        raise_errors: true,
        application_name: 'the-example-app.rb',
        application_version: '1.0.0'
      }
      options[:api_url] = 'preview.contentful.com' if is_preview

      ::Contentful::Client.new(options)
    end
  end
end
