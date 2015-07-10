require 'rails_helper'

RSpec.describe "sub_processes/new", type: :view do
  before(:each) do
    assign(:sub_process, SubProcess.new(
      :name => "MyString",
      :disabled => false,
      :protocol => nil,
      :admin => nil
    ))
  end

  it "renders new sub_process form" do
    render

    assert_select "form[action=?][method=?]", sub_processes_path, "post" do

      assert_select "input#sub_process_name[name=?]", "sub_process[name]"

      assert_select "input#sub_process_disabled[name=?]", "sub_process[disabled]"

      assert_select "input#sub_process_protocol_id[name=?]", "sub_process[protocol_id]"

      assert_select "input#sub_process_admin_id[name=?]", "sub_process[admin_id]"
    end
  end
end
