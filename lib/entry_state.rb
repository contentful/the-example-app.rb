module EntryState
  # Fetches the given entry from the Contentful Delivery API
  #
  # @param entry [Contentful::Entry] entry from the Contentful Preview API
  #
  # @return [Contentful::Entry]
  def published_entry(entry)
    contentful.entry(entry.id, 'cda')
  end

  # Creates `#draft` and `#pending_changes` singleton methods on the entry
  #
  # @param entry [Contentful::Entry]
  def attach_entry_state(entry)
    delivery_entry = published_entry(entry)
    entry.define_singleton_method(:draft) do
      delivery_entry.nil?
    end

    pending_changes_value = pending_changes?(entry, delivery_entry)
    entry.define_singleton_method(:pending_changes) do
      pending_changes_value
    end
  end

  # Compares the state of the entry to define if it's been updated
  #
  # @param preview_entry [Contentful::Entry]
  # @param delivery_entry [Contentful::Entry]
  #
  # @return [Boolean]
  def pending_changes?(preview_entry, delivery_entry)
    preview_entry && delivery_entry && (
        preview_entry.updated_at != delivery_entry.updated_at
    )
  end

  # Returns wether or not entry state pill should be shown
  #
  # @param entry [Contentful::Entry]
  #
  # @return [Boolean]
  def show_entry_state?(entry)
    current_api[:id] == 'cpa' && (entry.draft || entry.pending_changes)
  end

  # Returns wether or not state methods should be attached
  #
  # @return [Boolean]
  def attach_entry_state?
    session[:editorial_features] && current_api[:id] == 'cpa'
  end
end
