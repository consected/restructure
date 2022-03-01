# frozen_string_literal: true

# Display configuration information related to the server, to assist in fault finding
# and ensuring correct deployment
class Admin::ServerInfoController < AdminController
  def index
    si = Admin::ServerInfo.new(current_admin)

    @app_settings = si.app_settings
    @nfs_store_settings = si.nfs_store_settings
    @db_settings = si.db_settings
    @passenger_stats = si.passenger_status
    @passenger_memory_stats = si.passenger_memory_stats
    @processes = si.processes
    @disk_usage = si.disk_usage
    @instance_id = si.instance_id
    @nfs_store_mount_dirs = si.nfs_store_mount_dirs
    render 'admin/server_info/index'
  end
end
