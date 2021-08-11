# frozen_string_literal: true

# View a page layout as a standalone dashboard or page
class PageLayoutsController < ApplicationController
  before_action :authenticate_user_or_admin!
  before_action :index_authorized?, only: %i[index]
  before_action :show_authorized?, only: %i[show show_content]
  before_action :set_page_layout, only: %i[show show_content]
  before_action :set_page_filters, only: %i[show]
  attr_accessor :object_instance, :objects_instance

  def index
    self.objects_instance = @page_layouts = Admin::PageLayout.app_standalone_layouts(current_user.app_type_id)
  end

  def show
    render :show unless performed?
  end

  def show_content
    params[:filters] = params
    set_page_filters
    render :show unless performed?
  end

  private

  #
  # Only show the list of standalone layouts if the user can view dashboards
  # allowing them to see the list of available dashboards
  def index_authorized?
    return true if current_user.can?(:view_dashboards)

    not_authorized
  end

  #
  # A user can view a standalone layout if they can view dashboards or view pages
  def show_authorized?
    return true if current_user.can?(:view_dashboards) || current_user.can?(:view_pages)

    not_authorized
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

    @view_options = @page_layout.view_options

    self.object_instance = @page_layout
    #####################################
    # @todo handle users access controls
    #####################################
  end

  #
  # Filter results to appear in a page, using URL params like:
  # /page_layouts/page?filters[master_id]=105634
  # or the special /content routes
  # If the page layout configuration includes { view_options: { find_with: ext_id_name }}
  # /content/page/external-information/cohort-background-information
  # otherwise:
  # /content/page/ext-id-name/external-information/cohort-background-information
  def set_page_filters
    @filters = params[:filters]
    return unless @filters

    master_filter = {}
    master_filter[:id] = @filters[:master_id]

    master_filter[:type] = @view_options&.find_with || @filters[:master_type]&.hyphenate

    @master = Master.find_with master_filter, access_by: current_user
    return unless @master

    @master_id = @master.id
    @master.current_user = current_user
    return not_authorized unless @master.allows_user_access

    rid = @filters[:resource_id].to_i
    return @resource_id = rid if rid > 0

    secondary_key = @filters[:secondary_key]
    return @secondary_key = secondary_key if secondary_key.present?
  end
end
