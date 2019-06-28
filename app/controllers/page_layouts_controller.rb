class PageLayoutsController < ApplicationController
  before_action :authenticate_user_or_admin!
  before_action :authorized?
  before_action :set_page_layout, only: [:show]
  attr_accessor :object_instance, :objects_instance

  def index
    self.objects_instance = @page_layouts = app_standalone_layouts
  end

  def show
    render :show
  end

  private

    def authorized?
      return not_authorized unless current_user.can? :view_dashboards
    end

    def set_page_layout
      id ||= params[:id]
      return not_authorized if id.blank?

      num_id = id.to_i
      if num_id > 0
        @page_layout = app_standalone_layouts.find(id)
      else
        @page_layout = app_standalone_layouts.where(panel_name: id).first
      end

      return not_found unless @page_layout

      self.object_instance = @page_layout
      #####################################
      #@todo handle users access controls
      #####################################

    end

    def app_standalone_layouts
      Admin::PageLayout.active.standalone.where(app_type_id: current_user.app_type_id)
    end

end
