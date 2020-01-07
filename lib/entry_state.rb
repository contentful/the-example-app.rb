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

    draft_value = known_resources_for(entry, delivery_entry).any? do |(_preview_resource, delivery_resource)|
      delivery_resource.nil? || !['Entry', 'Asset'].include?(delivery_resource.type)
    end
    entry.define_singleton_method(:draft) do
      draft_value
    end

    pending_changes_value = known_resources_for(entry, delivery_entry).any? do |(preview_resource, delivery_resource)|
      pending_changes?(preview_resource, delivery_resource)
    end
    entry.define_singleton_method(:pending_changes) do
      pending_changes_value
    end
  end

  # Returns matching resources between Previw and Delivery APIs.
  # We check only for the main resource itself and for nested modules.
  #
  # @param preview_entry [Contentful::Entry] Entry from Preview API.
  # @param delivery_entry [Contentful::Entry] Entry from the Delivery API.
  #
  # @return [Array<Array<Contentful::Entry, Contentful::Entry>>]
  def known_resources_for(preview_entry, delivery_entry)
    resources = []
    preview_entry.fields.each do |field, value|
      if field.to_s.include?('modules')
        value.each do |preview_resource|
          resources << [
            preview_resource,
            find_matching_resource(
              preview_resource,
              delivery_entry,
              field
            )
          ]
        end
      end
    end
    resources << [preview_entry, delivery_entry]

    resources
  end

  # Returns matching resource for a specific field.
  #
  # @param preview_resource [Contentful::Entry] Entry from the Preview API to match.
  # @param delivery_entry [Contentful::Entry] Entry to search from, from the Delivery API.
  # @param search_field [String] Field in which to search in the delivery entry.
  #
  # @return [Contentful::Entry, nil] Entry from the Delivery API or nil.
  def find_matching_resource(preview_resource, delivery_entry, search_field)
    return nil unless delivery_entry

    _field, values = delivery_entry.fields.detect { |k, _v| k == search_field }
    return nil if values.nil?

    values.detect { |delivery_resource| delivery_resource.id == preview_resource.id }
  end

  # Compares the state of the entry to define if it's been updated
  #
  # @param preview_entry [Contentful::Entry]
  # @param delivery_entry [Contentful::Entry]
  #
  # @return [Boolean]
  def pending_changes?(preview_entry, delivery_entry)
    preview_entry && delivery_entry && (
        sanitize_date(preview_entry.updated_at) != sanitize_date(delivery_entry.updated_at)
    )
  end


  # In order to have a more accurate comparison due to minimal delays
  # upon publishing entries. We strip milliseconds from the dates we compare.
  #
  # @param date [::DateTime]
  # @return [::Time] without milliseconds.
  def sanitize_date(date)
    time = date.to_time

    ::Time.new(time.year, time.month, time.day, time.hour, time.min, time.sec, time.utc_offset)
  end

  # Returns wether or not entry state pill should be shown
  #
  # @param entry [Contentful::Entry]
  #
  # @return [Boolean]
  def show_entry_state?(entry)
    current_api[:id] == 'cpa' && (
      (entry.respond_to?(:draft) && entry.draft) ||
      (entry.respond_to?(:pending_changes) && entry.pending_changes)
    )
  end

  # Returns wether or not state methods should be attached
  #
  # @return [Boolean]
  def attach_entry_state?
    current_api[:id] == 'cpa' && session[:editorial_features]
  end
end
