require 'spec_helper'

class MockEntry
  attr_reader :id, :updated_at, :published_at

  def initialize(id, published_at, updated_at, fields = {})
    @id = id
    @published_at = published_at
    @updated_at = updated_at
    @fields = fields
  end

  def fields
    @fields
  end
end

class MockContentful
  def initialize(published_at, updated_at)
    @published_at = published_at
    @updated_at = updated_at
  end

  def entry(entry_id, _api_id)
    return nil if @published_at.nil?
    return MockEntry.new(entry_id, @published_at, @updated_at)
  end
end

class MockEntryState
  include EntryState

  def initialize(current_api = 'cda', editorial_features = false, delivery_published_at = DateTime.new(2017, 12, 14), delivery_updated_at = DateTime.new(2017, 12, 14))
    @current_api = current_api
    @editorial_features = editorial_features
    @delivery_published_at = delivery_published_at
    @delivery_updated_at = delivery_updated_at
  end

  def contentful
    MockContentful.new(@delivery_published_at, @delivery_updated_at)
  end

  def current_api
    { id: @current_api }
  end

  def session
    { editorial_features: @editorial_features }
  end
end

describe EntryState do
  describe 'instance methods' do
    describe '#attach_entry_state?' do
      it 'false when current api is not cpa' do
        expect(MockEntryState.new.attach_entry_state?).to eq false
      end

      it 'false when current api is cpa, but editorial features is false' do
        expect(MockEntryState.new('cpa').attach_entry_state?).to eq false
      end

      it 'true when current api is cpa and editorial features is true' do
        expect(MockEntryState.new('cpa', true).attach_entry_state?).to eq true
      end
    end

    describe '#pending_changes?' do
      it 'false if preview entry is nil' do
        expect(MockEntryState.new.pending_changes?(nil, 'foo')).to be_falsey
      end

      it 'false if delivery entry is nil' do
        expect(MockEntryState.new.pending_changes?('foo', nil)).to be_falsey
      end

      it 'false if both entries present but have same updated_at dates' do
        preview_entry = MockEntry.new('foo', DateTime.new(2017, 12, 14), DateTime.new(2017, 12, 14))
        delivery_entry = MockEntry.new('foo', DateTime.new(2017, 12, 14), DateTime.new(2017, 12, 14))

        expect(MockEntryState.new.pending_changes?(preview_entry, delivery_entry)).to be_falsey
      end

      it 'true if both entries have different updated_at dates' do
        preview_entry = MockEntry.new('foo', DateTime.new(2017, 12, 14), DateTime.new(2017, 12, 16))
        delivery_entry = MockEntry.new('foo', DateTime.new(2017, 12, 14), DateTime.new(2017, 12, 14))

        expect(MockEntryState.new.pending_changes?(preview_entry, delivery_entry)).to be_truthy
      end
    end

    describe '#show_entry_state?' do
      before :each do
        @entry = MockEntry.new('foo', DateTime.new(2017, 12, 14), DateTime.new(2017, 12, 14))
      end

      it 'false if current api is cda' do
        expect(MockEntryState.new.show_entry_state?(@entry)).to eq false
      end

      it 'false if current api is cpa, but entry is neither draft or pending changes' do
        entry_state = MockEntryState.new('cpa')
        entry_state.attach_entry_state(@entry)

        expect(entry_state.show_entry_state?(@entry)).to eq false
      end

      it 'true if current api is cpa and entry is draft' do
        entry_state = MockEntryState.new('cpa', false, nil)
        entry_state.attach_entry_state(@entry)

        expect(entry_state.show_entry_state?(@entry)).to eq true
      end

      it 'true if current api is cpa and entry is pending changes' do
        entry_state = MockEntryState.new('cpa', false, DateTime.new(2017, 12, 14), DateTime.new(2017, 12, 16))
        entry_state.attach_entry_state(@entry)

        expect(entry_state.show_entry_state?(@entry)).to eq true
      end
    end

    describe '#sanitize_date' do
      it 'removes milliseconds from a DateTime object' do
        time = DateTime.new(2017, 12, 14, 12, 30, 30, 123)
        expect(MockEntryState.new.sanitize_date(time).iso8601).to eq "2017-12-14T12:30:30+00:00"
      end
    end
  end
end
