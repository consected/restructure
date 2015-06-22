require 'rails_helper'

RSpec.describe "general_selections/show", type: :view do
  before(:each) do
    @general_selection = assign(:general_selection, GeneralSelection.create!(
      :name => "Name",
      :value => "Value",
      :item_type => "Item Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Value/)
    expect(rendered).to match(/Item Type/)
  end
end
