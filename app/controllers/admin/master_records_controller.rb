# frozen_string_literal: true

# Admin controller for the "Master Records" admin page (issue #930).
#
# This is a read-only admin page that appears under the Definitions section of
# the admin index. It shows:
#   - An informational header about the masters table (crosswalk fields,
#     readonly attrs, temporary master IDs, search link)
#   - A table of the standard models / tables associated with masters
#     (player_infos, pro_infos, player_contacts, addresses, trackers,
#     tracker_histories), with a "Show" button per row that opens a
#     tabbed detail panel (Details, Sample Form, UAC, API).
#
# No create / update / destroy actions exist — the resource is read-only.
class Admin::MasterRecordsController < AdminController
  # Use a custom object_name so that instance variables follow the
  # @admin_object / @admin_objects convention expected by the spec tests.
  def object_name
    'admin_object'
  end

  def human_name
    'Master Record Model'
  end

  def title
    'Master Records'
  end

  # -------------------------------------------------------------------
  # Actions
  # -------------------------------------------------------------------

  def index
    @admin_objects = Admin::MasterRecord.all
    @masters_info = build_masters_info
    render 'admin/master_records/index'
  end

  def show
    @admin_object = Admin::MasterRecord.find(params[:id])
    render partial: 'admin/master_records/show_panel',
           locals: { object_instance: @admin_object }
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  protected

  # Guard this page with a dedicated :master_records capability so that
  # access can be granted independently of :dynamic_models or other caps.
  def capability_name
    :master_records
  end

  # Never allow creating records via this controller.
  def no_create
    true
  end

  # Never allow editing records via this controller.
  def no_edit
    true
  end

  private

  # Build the metadata hash shown in the informational header of the index page.
  # @return [Hash]
  def build_masters_info
    {
      crosswalk_attrs: Master.crosswalk_attrs,
      readonly_attrs: Master.readonly_attrs,
      temporary_master_ids: Master::TemporaryMasterIds
    }
  end
end
