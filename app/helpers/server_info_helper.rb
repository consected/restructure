# frozen_string_literal: true

# Helper methods for admin server info display
module ServerInfoHelper
  # Render a Bootstrap status label for NFS mount status
  # @param status [Symbol] the status symbol (:mounted, :failed, :accessible, :not_configured, :error)
  # @return [String] HTML for Bootstrap label
  def nfs_status_label(status)
    label_class, label_text = case status
                              when Admin::ServerInfo::NFS_STATUS_MOUNTED,
                                   Admin::ServerInfo::NFS_STATUS_ACCESSIBLE
                                ['label-success', status.to_s]
                              when Admin::ServerInfo::NFS_STATUS_NOT_CONFIGURED
                                ['label-warning', 'not configured']
                              else
                                ['label-danger', status.to_s]
                              end

    content_tag(:span, label_text, class: "label #{label_class}")
  end
end
