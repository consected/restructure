require 'rails_helper'

RSpec.configure {|c| c.before {
  SeedSupport.setup
}}


RSpec.describe ScantronsController, type: :controller do

  include ScantronSupport

  def object_class
    Scantron
  end

  def item
    @scantron
  end

  def edit_form_name
    @edit_form_name = "_edit_form"
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

  before :each do
    seed_database
  end

  it_behaves_like 'a standard user controller'

end
