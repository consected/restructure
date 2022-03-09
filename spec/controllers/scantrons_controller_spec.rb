# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScantronsController, type: :controller do
  include ScantronSupport

  def object_class
    current_scantron_model
  end

  def item
    @scantron
  end

  def edit_form_name
    @edit_form_name = '_edit_form'
  end

  def edit_form_prefix
    @edit_form_prefix = 'common_templates'
  end

  before(:context) do
    # seed_database
    # Handle a strange issue during full test runs
    res = ExternalIdentifier.active.where(name: 'scantrons').count
    expect(res).to eq 1

    ActivityLog.preload
    ExternalIdentifier.routes_reload
    expect(object_class.to_s).to eq 'Scantron'

    delete_previous_records
  end

  before :each do
    # seed_database
  end

  it_behaves_like 'a standard user controller'
end
