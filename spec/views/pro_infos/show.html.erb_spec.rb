require 'rails_helper'

RSpec.describe "pro_infos/show", type: :view do
  before(:each) do
    @pro_info = assign(:pro_info, ProInfo.create!(
      :master => nil,
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
