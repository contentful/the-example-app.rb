require 'spec_helper'

describe Routes::Settings do
  describe 'get /settings' do
    it 'renders settings page' do
      visit route('/settings')

      expect(page).to have_content 'To query and get content using the APIs, client applications need to authenticate with both the Space ID and an access token.'
      expect(page).to have_content 'The example app v1'
    end
  end

  describe 'post /settings' do
    it 'updates values' do
      visit route('/settings')

      fill_in "Space ID", with: '2qyxj1hqedht'
      fill_in "Content Delivery API access token", with: '97dd6f2251320afebc6416acb12a6c47ac836bbaea815eb55e7d2d59b80e79f3'
      fill_in "Content Preview API access token", with: 'bfc009b1ec707da40d875e1942dbb009eea7d1c19785b7dbd90ecf2cdfd1d989'

      click_button 'Save settings'

      expect(page).to have_content 'TEA'
      expect(page.status_code).to eq 201
    end
  end

  describe 'post /reset' do
    it 'resets the session' do
      # Setup
      visit route('/settings')

      fill_in "Space ID", with: '2qyxj1hqedht'
      fill_in "Content Delivery API access token", with: '97dd6f2251320afebc6416acb12a6c47ac836bbaea815eb55e7d2d59b80e79f3'
      fill_in "Content Preview API access token", with: 'bfc009b1ec707da40d875e1942dbb009eea7d1c19785b7dbd90ecf2cdfd1d989'

      click_button 'Save settings'

      expect(page).to have_content 'TEA'

      # Test
      click_button 'Reset credentials to default'

      expect(page).to have_content 'The example app v1'
    end
  end

  describe 'errors' do
    it 'display field required errors if on any of the text inputs if input is missing' do
      visit route('/settings')

      fill_in "Space ID", with: ''
      fill_in "Content Delivery API access token", with: '97dd6f2251320afebc6416acb12a6c47ac836bbaea815eb55e7d2d59b80e79f3'
      fill_in "Content Preview API access token", with: 'bfc009b1ec707da40d875e1942dbb009eea7d1c19785b7dbd90ecf2cdfd1d989'

      click_button 'Save settings'

      expect(page).to have_content 'Some errors occurred. Please check the error messages next to the fields.'
      expect(page).to have_content 'This field is required'
      expect(page.status_code).to eq 409
    end

    it 'displays space/token error if space or token are incorrect' do
      visit route('/settings')

      fill_in "Space ID", with: 'foobar'
      fill_in "Content Delivery API access token", with: '97dd6f2251320afebc6416acb12a6c47ac836bbaea815eb55e7d2d59b80e79f3'
      fill_in "Content Preview API access token", with: 'bfc009b1ec707da40d875e1942dbb009eea7d1c19785b7dbd90ecf2cdfd1d989'

      click_button 'Save settings'

      expect(page).to have_content 'Some errors occurred. Please check the error messages next to the fields.'
      expect(page).to have_content 'This space does not exist or your access token is not associated with your space.'
      expect(page.status_code).to eq 409
    end
  end
end
