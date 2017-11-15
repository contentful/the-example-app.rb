module EntryState
  def published_entry(entry)
    contentful.entry(entry.id, 'cda')
  end

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

  def pending_changes?(preview_entry, delivery_entry)
    preview_entry && delivery_entry && (
        preview_entry.updated_at != delivery_entry.updated_at
    )
  end

  def show_entry_state?(entry)
    current_api[:id] == 'cpa' && (entry.draft || entry.pending_changes)
  end

  def attach_entry_state?
    session[:editorial_features] && current_api[:id] == 'cpa'
  end
end
