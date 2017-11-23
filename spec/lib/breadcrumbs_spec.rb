require 'spec_helper'

class MockRequest
  attr_reader :path

  def initialize(path = '/')
    @path = path
  end
end

class MockResource
  attr_reader :slug, :title

  def initialize(slug = '', title = '')
    @slug = slug
    @title = title
  end
end

describe Breadcrumbs do
  subject { described_class }
  let(:english) { ::Contentful::Locale.new('code' => 'en-US') }
  let(:german) { ::Contentful::Locale.new('code' => 'de-DE') }


  before :all do
    I18n.initialize_translations
  end

  describe 'class methods' do
    describe '::breadcrumbs' do
      it 'by default it adds home' do
        request = MockRequest.new

        expect(subject.breadcrumbs(request, english)).to include(url: '/', label: 'Home')
      end

      it 'adds all parts of the URL' do
        request = MockRequest.new('/courses/foobar/lessons')

        expect(subject.breadcrumbs(request, english)).to eq [
          { url: '/', label: 'Home' },
          { url: '/courses', label: 'Courses' },
          { url: '/courses/foobar', label: 'foobar' },
          { url: '/courses/foobar/lessons', label: 'Lessons' }
        ]
      end

      it 'localizes static parts of the URL' do
        request = MockRequest.new('/courses/foobar/lessons')

        expect(subject.breadcrumbs(request, german)).to eq [
          { url: '/', label: 'Startseite' },
          { url: '/courses', label: 'Kurse' },
          { url: '/courses/foobar', label: 'foobar' },
          { url: '/courses/foobar/lessons', label: 'Lektionen' }
        ]
      end
    end

    describe '::refine' do
      let(:crumbs) { subject.breadcrumbs(MockRequest.new('/courses/foobar/lessons'), english) }

      it 'does nothing if no slugs match' do
        expect(subject.refine(crumbs, MockResource.new)).to eq crumbs
      end

      it 'replaces dynamic parts of the URLs with resource titles if available' do
        expect(subject.refine(crumbs, MockResource.new('foobar', 'Some Foo Bar!'))).to include(url: '/courses/foobar', label: 'Some Foo Bar!')
      end
    end
  end
end
