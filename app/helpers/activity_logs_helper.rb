module ActivityLogsHelper

  def activity_log_edit_form_hash extras={}
    extras.merge({url: "/masters/#{@master.id}/#{@item.item_type}/#{@item.id}/activity_logs", action: :post, remote: true, html: {"data-result-target" => "#activity-log-#{@master.id}-entry-block", "data-template" => "activity-logs-result-template"}})
  end

end