require 'spec_helper'

describe I18n do
  subject { described_class }
  let(:english) { 'en-US' }
  let(:german) { 'de-DE' }

  before :all do
    I18n.initialize_translations
  end

  describe 'class methods' do
    describe '::translation_available?' do
      it 'false if no translation available for symbol' do
        expect(subject.translation_available?('doesntExist', english)).to eq false
      end

      it 'false if no translation file available' do
        expect(subject.translation_available?('coursesLabel', 'unknown-Locale')).to eq false
      end

      it 'true if locale is found and symbol exists' do
        expect(subject.translation_available?('coursesLabel', english)).to eq true
      end
    end

    describe '::translate' do
      it 'returns an error string when locale file is not found' do
        expect(subject.translate('coursesLabel', 'unknown-Locale')).to eq 'Localization file for unknown-Locale is not available'
      end

      it 'returns an error string when symbol is not found for locale' do
        expect(subject.translate('doesntExist', english)).to eq 'Translation not found for doesntExist in en-US'
      end

      it 'returns translated string when symbol is found for locale' do
        expect(subject.translate('coursesLabel', english)).to eq 'Courses'
        expect(subject.translate('coursesLabel', german)).to eq 'Kurse'
      end
    end
  end
end
