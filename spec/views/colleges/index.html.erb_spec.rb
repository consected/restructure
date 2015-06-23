require 'rails_helper'

RSpec.describe "colleges/index", type: :view do
  before(:each) do
    assign(:colleges, [
      College.create!(
        :name => "Name",
        :synonym_for_id => 1
      ),
      College.create!(
        :name => "Name",
        :synonym_for_id => 1
      )
    ])
  end

  it "renders a list of colleges" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
