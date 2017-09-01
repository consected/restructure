module ActivityLogsHelper

  def activity_log_edit_form_hash extras={}
    extras.merge({url: "/masters/#{@master.id}/#{@item.item_type.pluralize}/#{@item.id}/#{object_instance.item_type.pluralize}", action: :post, remote: true, html: {"data-result-target" => "#activity-log-#{@master.id}-entry-block", "data-template" => "activity-logs-result-template"}})
  end

end