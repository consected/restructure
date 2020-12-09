# frozen_string_literal: true

# View a page layout as a standalone dashboard or page
class PageLayoutsController < ApplicationController
  before_action :authenticate_user_or_admin!
  before_action :authorized?
  before_action :set_page_layout, only: [:show]
  before_action :set_page_filters, only: [:show]
  attr_accessor :object_instance, :objects_instance

  def index
    self.objects_instance = @page_layouts = Admin::PageLayout.app_standalone_layouts(current_user.app_type_id)
  end

  def show
    render :show
  end

  def show_content; end

  private

  def authorized?
    return not_authorized unless current_user.can? :view_dashboards
  end

  def active_layouts
    Admin::PageLayout.app_show_layouts(current_user.app_type_id)
  end

  def set_page_layout
    id ||= params[:id]
    return not_authorized if id.blank?

    num_id = id.to_i
    @page_layout = if num_id > 0
                     active_layouts.find(id)
                   else
                     active_layouts.where(panel_name: id).first
                   end

    return not_found unless @page_layout

    self.object_instance = @page_layout
    #####################################
    # @todo handle users access controls
    #####################################
  end

  #
  # Filter results to appear in a page, using URL params like:
  # /page_layouts/page?filters[master_id]=105634
  def set_page_filters
    @filters = params[:filters]

    master_id = @filters[:master_id] if @filters
    return unless master_id

    @master = Master.find(master_id)
    @master_id = @master.id
    @master.current_user = current_user
    return not_authorized unless @master.allows_user_access

    rid = @filters[:resource_id].to_i
    @resource_id = rid if rid > 0
  end
end
