# frozen_string_literal: true

#
# Provide helpers to support protocol / sub process / protocol event fields and views
module ProtocolsHelper
  #
  # Generate an array of protocol name / protocol IDs for fields.
  # The current user's app type is used to limit protocols, unless *app_type_id* is specified.
  # A special case is when *admin_view: true*, which shows all app types.
  # @param [Integer] app_type_id - optional Admin::AppType#id, or use current user's by default
  # @param [Boolean] admin_view - if true, limit to the current or specified app type
  # @return [Array{String, Integer}]
  def protocol_array(app_type_id: nil, admin_view: false)
    conditions = {}
    app_type_id ||= current_user.app_type_id
    conditions = { app_type_id: [app_type_id, nil] } unless admin_view
    Classification::Protocol.selector_array_pair(conditions)
  end

  #
  # Generate an array of protocol name / protocol IDs for fields, excluding Updates protocol
  # The current user's app type is used to limit protocols, unless *app_type_id* is specified.
  # A special case is when *admin_view: true*, which shows all app types.
  # @param [Integer] app_type_id - optional Admin::AppType#id, or use current user's by default
  # @param [Boolean] admin_view - if true, limit to the current or specified app type
  # @return [Array{String, Integer}]
  def protocol_array_without_updates(app_type_id: nil, admin_view: false)
    protocol_array(admin_view: admin_view, app_type_id: app_type_id)
      .reject { |a| a.first == Classification::Protocol::RecordUpdatesProtocolName }
  end

  #
  # Get an Admin::AppType#id by id or name (or return nil if supplied value is nil)
  # @param [Integer | String | nil] id_or_name
  # @return [Admin::AppType | nil]
  def app_type_id_by_id_or_name(id_or_name)
    case id_or_name
    when Integer
      Admin::AppType.find_by_id(id_or_name)&.id
    when String
      Admin::AppType.find_by_name(id_or_name)&.id
    end
  end

  def sub_processes_array
    res = Classification::SubProcess.selector_attributes %i[name id protocol_name]
    res.map { |a| ["#{a.last} - #{a.first}", a[1]] }
  end

  def sub_processes_array_with_class
    res = Classification::SubProcess.selector_attributes %i[name id protocol_id]

    res.map { |a| [a.first, a[1], { 'data-filter-id' => a.last }] }
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

    res.map { |a| [a.first, a.first.downcase, { 'data-filter-id' => a.last }] }
  end
end
