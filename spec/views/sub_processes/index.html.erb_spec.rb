require 'rails_helper'

RSpec.describe "sub_processes/index", type: :view do
  before(:each) do
    assign(:sub_processes, [
      SubProcess.create!(
        :name => "Name",
        :disabled => false,
        :protocol => nil,
        :admin => nil
      ),
      SubProcess.create!(
        :name => "Name",
        :disabled => false,
        :protocol => nil,
        :admin => nil
      )
    ])
  end

  it "renders a list of sub_processes" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
