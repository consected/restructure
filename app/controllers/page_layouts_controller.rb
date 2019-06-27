class PageLayoutsController < ApplicationController
  before_action :authenticate_user_or_admin!
  before_action :set_page_layout, only: [:show]
  attr_accessor :object_instance

  def index
    @page_layouts = Admin::PageLayout.active.standalone
  end

  # Simple action to refresh the session timeout
  def show
    render :show
  end

  private

  def set_page_layout
    id ||= params[:id]
    return not_authorized if id.blank?

    num_id = id.to_i
    if num_id > 0
      @page_layout = Admin::PageLayout.active.standalone.where(app_type_id: current_user.app_type_id).find(id)
    else
      @page_layout = Admin::PageLayout.active.standalone.where(app_type_id: current_user.app_type_id).where(panel_name: id).first
    end

    self.object_instance = @page_layout
    #####################################
    #@todo handle users access controls
    #####################################

  end

end
