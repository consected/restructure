require 'rails_helper'

RSpec.describe "protocol_outcomes/edit", type: :view do
  before(:each) do
    @protocol_outcome = assign(:protocol_outcome, ProtocolOutcome.create!(
      :name => "MyString",
      :protocol => nil,
      :admin => nil
    ))
  end

  it "renders the edit protocol_outcome form" do
    render

    assert_select "form[action=?][method=?]", protocol_outcome_path(@protocol_outcome), "post" do

      assert_select "input#protocol_outcome_name[name=?]", "protocol_outcome[name]"

      assert_select "input#protocol_outcome_protocol_id[name=?]", "protocol_outcome[protocol_id]"

      assert_select "input#protocol_outcome_admin_id[name=?]", "protocol_outcome[admin_id]"
    end
  end
end
