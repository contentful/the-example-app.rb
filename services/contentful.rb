require 'contentful'

module Services
  class Contentful
    # Gets or creates a Contentful Service Wrapper
    #
    # @param space_id [String]
    # @param delivery_token [String]
    # @param preview_token [String]
    #
    # @return [Services::Contentful]
    def self.instance(space_id, delivery_token, preview_token)
      @instance ||= nil

      # We create new client instances only if credentials changed or client wasn't instantiated before
      if @instance.nil? || (
          @instance.space_id != space_id ||
          @instance.delivery_token != delivery_token ||
          @instance.preview_token != preview_token
        )
        @instance = new(space_id, delivery_token, preview_token)
      end

      @instance
    end

    # Creates a Contentful client
    #
    # @param space_id [String]
    # @param access_token [String] Delivery or Preview API access token
    # @param is_preview [Boolean] wether or not the client uses the Preview API
    #
    # @return [::Contentful::Client]
    def self.create_client(space_id, access_token, is_preview = false)
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

    attr_reader :space_id, :delivery_token, :preview_token

    # Returns the corresponding client (Delivery or Preview)
    #
    # @param api_id [String]
    #
    # @return [::Contentful::Client]
    def client(api_id)
      api_id == 'cda' ? @delivery_client : @preview_client
    end

    # Returns the current space
    #
    # @param api_id [String]
    #
    # @return [::Contentful::Space]
    def space(api_id)
      client(api_id).space
    end

    # Finds all courses, optionally filters them
    #
    # @param api_id [String]
    # @param locale [String]
    # @param options [Hash] filters for the Search API
    #
    # @return [Array<::Contentful::Entry>]
    def courses(api_id = 'cda', locale = 'en-US', options = {})
      options = {
        content_type: 'course',
        locale: locale,
        order: '-sys.createdAt',
        include: 6
      }.merge(options)

      client(api_id).entries(options)
    end

    # Finds a course by slug
    #
    # @param slug [String]
    # @param api_id [String]
    # @param locale [String]
    #
    # @return [::Contentful::Entry]
    def course(slug, api_id = 'cda', locale = 'en-US')
      courses(api_id, locale, 'fields.slug' => slug)[0]
    end

    # Finds all courses by category
    #
    # @param category_id [String]
    # @param api_id [String]
    # @param locale [String]
    #
    # @return [Array<::Contentful::Entry>]
    def courses_by_category(category_id, api_id = 'cda', locale = 'en-US')
      courses(api_id, locale, 'fields.categories.sys.id' => category_id)
    end

    # Finds all categories
    #
    # @param api_id [String]
    # @param locale [String]
    #
    # @return [Array<::Contentful::Entry>]
    def categories(api_id = 'cda', locale = 'en-US')
      client(api_id).entries(
        content_type: 'category',
        locale: locale
      )
    end

    # Finds a landing page (layout) by slug
    #
    # @param slug [String]
    # @param api_id [String]
    # @param locale [String]
    #
    # @return [::Contentful::Entry]
    def landing_page(slug, api_id = 'cda', locale = 'en-US')
      client(api_id).entries(
        content_type: 'layout',
        locale: locale,
        include: 6,
        'fields.slug' => slug
      )[0]
    end

    # Returns an entry by ID
    #
    # @param entry_id [String]
    # @param api_id [String]
    #
    # @return [::Contentful::Entry]
    def entry(entry_id, api_id)
      client(api_id).entry(entry_id)
    end

    private

    def initialize(space_id, delivery_token, preview_token)
      @space_id = space_id
      @delivery_token = delivery_token
      @preview_token = preview_token

      @delivery_client = self.class.create_client(@space_id, @delivery_token)
      @preview_client = self.class.create_client(@space_id, @preview_token, true)
    end
  end
end
