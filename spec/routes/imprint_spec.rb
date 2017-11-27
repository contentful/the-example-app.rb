require 'spec_helper'

describe Routes::Imprint do
  describe '/imprint' do
    it 'renders imprint page' do
      visit route('/imprint')
      expect(page).to have_content 'Company'
      expect(page).to have_content 'Contentful GmbH'
    end
  end
end
