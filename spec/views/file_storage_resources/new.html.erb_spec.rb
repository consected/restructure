require 'rails_helper'

RSpec.describe "file_storage_resources/new", type: :view do
  before(:each) do
    assign(:file_storage_resource, FileStorageResource.new(
      :name => "MyString",
      :s3_url => "MyString",
      :notes => "MyString",
      :user => nil
    ))
  end

  it "renders new file_storage_resource form" do
    render

    assert_select "form[action=?][method=?]", file_storage_resources_path, "post" do

      assert_select "input#file_storage_resource_name[name=?]", "file_storage_resource[name]"

      assert_select "input#file_storage_resource_s3_url[name=?]", "file_storage_resource[s3_url]"

      assert_select "input#file_storage_resource_notes[name=?]", "file_storage_resource[notes]"

      assert_select "input#file_storage_resource_user_id[name=?]", "file_storage_resource[user_id]"
    end
  end
end
