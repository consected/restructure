require 'rails_helper'

RSpec.describe "sub_processes/edit", type: :view do
  before(:each) do
    @sub_process = assign(:sub_process, SubProcess.create!(
      :name => "MyString",
      :disabled => false,
      :protocol => nil,
      :admin => nil
    ))
  end

  it "renders the edit sub_process form" do
    render

    assert_select "form[action=?][method=?]", sub_process_path(@sub_process), "post" do

      assert_select "input#sub_process_name[name=?]", "sub_process[name]"

      assert_select "input#sub_process_disabled[name=?]", "sub_process[disabled]"

      assert_select "input#sub_process_protocol_id[name=?]", "sub_process[protocol_id]"

      assert_select "input#sub_process_admin_id[name=?]", "sub_process[admin_id]"
    end
  end
end
