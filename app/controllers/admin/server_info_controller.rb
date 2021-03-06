# frozen_string_literal: true

# Display configuration information related to the server, to assist in fault finding
# and ensuring correct deployment
class Admin::ServerInfoController < AdminController
  def index
    si = Admin::ServerInfo.new(current_admin)

    @app_settings = si.app_settings
    @db_settings = si.db_settings
    @passenger_stats = si.passenger_status
    @passenger_memory_stats = si.passenger_memory_stats
    @processes = si.processes
    render 'admin/server_info/index'
  end
end
