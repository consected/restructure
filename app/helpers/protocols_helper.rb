# frozen_string_literal: true

module ProtocolsHelper
  def protocol_array(admin_view: false)
    conditions = {}
    conditions = { app_type_id: [current_user.app_type_id, nil] } unless admin_view
    res = Classification::Protocol.selector_array_pair(conditions)
    res
  end

  def protocol_array_without_updates(admin_view: false)
    res = protocol_array(admin_view: admin_view).reject { |a| a.first == Classification::Protocol::RecordUpdatesProtocolName }
    res
  end

  def sub_processes_array
    res = Classification::SubProcess.selector_attributes %i[name id protocol_name]
    res = res.map { |a| ["#{a.last} - #{a.first}", a[1]] }
    res
  end

  def sub_processes_array_with_class
    res = Classification::SubProcess.selector_attributes %i[name id protocol_id]

    res = res.map { |a| [a.first, a[1], { 'data-filter-id' => a.last }] }

    res
  end

  def protocol_events_array_with_class(options = {})
    res = Classification::ProtocolEvent.selector_attributes %i[name id sub_process_id]

    pes = res.collect { |a| a[2] }

    if options[:add_empty]
      # look for missing items
      missing = []
      sub_processes_array.each do |a|
        missing << [options[:add_empty], '(null)', { 'data-filter-id' => a[1] }] unless pes.include? a[1]
      end

    end

    res = res.select(&:last).map { |a| [a.first, a[1], { 'data-filter-id' => a.last }] }

    res += missing if missing

    res
  end

  def protocol_events_name_array_with_class
    res = Classification::ProtocolEvent.selector_attributes %i[name sub_process_id]

    res = res.map { |a| [a.first, a.first.downcase, { 'data-filter-id' => a.last }] }

    res
  end
end
