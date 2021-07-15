# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::GeneralSelectionsController, type: :controller do
  include GeneralSelectionSupport

  def object_class
    Classification::GeneralSelection
  end

  def item
    @general_selection
  end

  def saved_item_template
    'admin/general_selections/_item'
  end

  before(:context) do
    @path_prefix = '/admin'
  end

  before :example do
    connection = ActiveRecord::Base.connection
    connection.execute('delete from general_selection_history')
    @path_prefix = '/admin'
    Classification::GeneralSelection.destroy_all
  end

  it_behaves_like 'a standard admin controller'
end
