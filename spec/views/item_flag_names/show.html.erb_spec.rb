require 'rails_helper'

RSpec.describe "item_flag_names/show", type: :view do
  before(:each) do
    @item_flag_name = assign(:item_flag_name, ItemFlagName.create!(
      :name => "Name",
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
  end
end
