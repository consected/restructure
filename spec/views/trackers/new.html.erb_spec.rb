require 'rails_helper'

RSpec.describe "trackers/new", type: :view do
  before(:each) do
    assign(:tracker, Tracker.new(
      :master => nil,
      :protocol => nil,
      :event => "MyString",
      :c_method => "MyString",
      :outcome => "MyString",
      :user => nil
    ))
  end

  it "renders new tracker form" do
    render

    assert_select "form[action=?][method=?]", trackers_path, "post" do

      assert_select "input#tracker_master_id[name=?]", "tracker[master_id]"

      assert_select "input#tracker_protocol_id[name=?]", "tracker[protocol_id]"

      assert_select "input#tracker_event[name=?]", "tracker[event]"

      assert_select "input#tracker_c_method[name=?]", "tracker[c_method]"

      assert_select "input#tracker_outcome[name=?]", "tracker[outcome]"

      assert_select "input#tracker_user_id[name=?]", "tracker[user_id]"
    end
  end
end
