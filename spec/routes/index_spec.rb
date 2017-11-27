require 'spec_helper'

describe Routes::Index do
  describe '/' do
    it 'renders index page' do
      visit route('/')
      expect(page).to have_content 'Learn how to build your own applications with Contentful.'
      expect(page).to have_content 'view course'
    end
  end
end
