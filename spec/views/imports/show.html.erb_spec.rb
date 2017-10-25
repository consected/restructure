require 'rails_helper'

RSpec.describe "imports/show", type: :view do
  before(:each) do
    @import = assign(:import, Import.create!(
      :primary_table => "Primary Table",
      :item_count => 2,
      :filename => "Filename",
      :items => "",
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Primary Table/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Filename/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
