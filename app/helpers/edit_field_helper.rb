# frozen_string_literal: true

module EditFieldHelper
  #
  # Gets the #data for each record for a select on an association or class name
  # @todo handle this correctly in a dynamic model. Currently this appears to only support activity logs
  #
  # @param [UserBase] form_object_instance the current instance for the form object
  # @param [String] assoc_or_class_name a master association name or an underscored class name to select from
  # @return [Array(String, Array(Array, Array))] a human name string and a list of data from the matched records
  #
  def list_record_data_for_select(form_object_instance, assoc_or_class_name)
    if ActivityLog.use_with_class_names.include?(assoc_or_class_name)
      # We matched one of the possible classes an activity log be used with (really these are master associations)
      reslist = form_object_instance.master.send(assoc_or_class_name.pluralize)
      cl = reslist.first&.class
      if cl
        if cl.attribute_names.include?('rank')
          reslist = reslist.order(rank: :desc)
          reslist_data = reslist.all.map { |i| ["#{i.data} [#{i.rank_name}]", i.data] }
        else
          reslist = reslist.order(data: :asc)
          reslist_data = reslist.all.map { |i| [i.data, i.data] }
        end
      end
    elsif (ActivityLog.all_valid_item_and_rec_types - ActivityLog.use_with_class_names).include? assoc_or_class_name
      # We matched one of the valid item and rec_types
      ActivityLog.use_with_class_names.each do |ucn|
        next unless assoc_or_class_name.start_with?(ucn)

        # Ensure that the class supporting the association has loaded
        # Item classes such as PlayerContact don't always load until referenced in the application.
        # When they provide dynamically generated rec_type associations in their setup the associations won't exist
        # Just touch the base class to get it set up, and the dynamic associations to be configured.
        ucn.camelize.constantize

        reslist = form_object_instance.master.send(assoc_or_class_name.pluralize).where(rec_type: assoc_or_class_name.sub(/^#{ucn}_/, ''))
        cl = reslist.first&.class
        if cl
          if cl.attribute_names.include?('rank')
            reslist = reslist.order(rank: :desc)
            reslist_data = reslist.all.map { |i| ["#{i.data} [#{i.rank_name}]", i.data] }
          else
            reslist = reslist.order(data: :asc)
            reslist_data = reslist.all.map { |i| [i.data, i.data] }
          end
        end
        break
      end
    end

    if cl
      human_name = cl.human_name
    else
      logger.warn "Failed to find valid class name for #{assoc_or_class_name}"
    end

    # In case no results were found
    reslist_data ||= []

    [human_name, reslist_data]
  end
end
