class ContainerListController < NfsStore::FsBaseController

  layout 'nfs_store'

  def index
    @containers = NfsStore::Manage::Container.for_current_app_type current_user
  end

  def new
    NfsStore::Manage::Container.create_in_current_app name: "Container #{rand(1000000)}", user: current_user
    redirect_to '/container_list'
  end
end
