require 'rails_helper'

RSpec.describe "trackers/edit", type: :view do
  before(:each) do
    @tracker = assign(:tracker, Tracker.create!(
      :master => nil,
      :protocol => nil,
      :event => "MyString",
      :c_method => "MyString",
      :outcome => "MyString",
      :user => nil
    ))
  end

  it "renders the edit tracker form" do
    render

    assert_select "form[action=?][method=?]", tracker_path(@tracker), "post" do

      assert_select "input#tracker_master_id[name=?]", "tracker[master_id]"

      assert_select "input#tracker_protocol_id[name=?]", "tracker[protocol_id]"

      assert_select "input#tracker_event[name=?]", "tracker[event]"

      assert_select "input#tracker_c_method[name=?]", "tracker[c_method]"

      assert_select "input#tracker_outcome[name=?]", "tracker[outcome]"

      assert_select "input#tracker_user_id[name=?]", "tracker[user_id]"
    end
  end
end
