require 'rails_helper'

RSpec.describe "pro_infos/index", type: :view do
  before(:each) do
    assign(:pro_infos, [
      ProInfo.create!(
        :master => nil,
        :user => nil
      ),
      ProInfo.create!(
        :master => nil,
        :user => nil
      )
    ])
  end

  it "renders a list of pro_infos" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
