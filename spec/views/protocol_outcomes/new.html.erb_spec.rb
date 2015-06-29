require 'rails_helper'

RSpec.describe "protocol_outcomes/new", type: :view do
  before(:each) do
    assign(:protocol_outcome, ProtocolOutcome.new(
      :name => "MyString",
      :protocol => nil,
      :admin => nil
    ))
  end

  it "renders new protocol_outcome form" do
    render

    assert_select "form[action=?][method=?]", protocol_outcomes_path, "post" do

      assert_select "input#protocol_outcome_name[name=?]", "protocol_outcome[name]"

      assert_select "input#protocol_outcome_protocol_id[name=?]", "protocol_outcome[protocol_id]"

      assert_select "input#protocol_outcome_admin_id[name=?]", "protocol_outcome[admin_id]"
    end
  end
end
