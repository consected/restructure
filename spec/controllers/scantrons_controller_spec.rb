require 'rails_helper'
RSpec.describe ScantronsController, type: :controller do

  include ScantronSupport

  def object_class
    Scantron
  end

  def item
    @scantron
  end

  def edit_form_name
    @edit_form_name = "_external_id_edit_form"
  end

  def edit_form_prefix
    @edit_form_prefix = "common_templates"
  end

  before(:all) do
    seed_database
    # Handle a strange issue during full test runs
    ExternalIdentifier.routes_reload

    delete_previous_records
  end


  it_behaves_like 'a standard user controller'

end
