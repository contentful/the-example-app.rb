require 'spec_helper'

describe ExampleApp do
  def app
    ExampleApp
  end

  describe 'routes are present' do
    it '/' do
      get route('/')
      expect(last_response.ok?).to eq true
    end

    it '/courses' do
      get route('/courses')
      expect(last_response.ok?).to eq true
    end

    it '/courses/:slug' do
      get route('/courses/hello-contentful')
      expect(last_response.ok?).to eq true
    end

    it '/courses/categories' do
      get route('/courses/categories')
      expect(last_response.status).to eq 302
    end

    it '/courses/categories/:slug' do
      get route('/courses/categories/getting-started')
      expect(last_response.ok?).to eq true
    end

    it '/courses/:slug/lessons' do
      get route('/courses/hello-world/lessons')
      expect(last_response.status).to eq 302
    end

    it '/courses/:c_slug/lessons/:l_slug' do
      get route('/courses/hello-contentful/lessons/apis')
      expect(last_response.ok?).to eq true
    end

    describe '/settings' do
      it 'get' do
        get route('/settings')
        expect(last_response.ok?).to eq true
      end

      it 'post' do
        post route('/settings'), {
          spaceId: ENV['CONTENTFUL_SPACE_ID'],
          deliveryToken: ENV['CONTENTFUL_DELIVERY_TOKEN'],
          previewToken: ENV['CONTENTFUL_PREVIEW_TOKEN']
        }

        expect(last_response.status).to eq 201
      end
    end

    it '/imprint' do
      get route('/imprint')
      expect(last_response.ok?).to eq true
    end
  end
end
