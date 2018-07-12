require 'rails_helper'

RSpec.describe "file_storage_resources/index", type: :view do
  before(:each) do
    assign(:file_storage_resources, [
      FileStorageResource.create!(
        :name => "Name",
        :s3_url => "S3 Url",
        :notes => "Notes",
        :user => nil
      ),
      FileStorageResource.create!(
        :name => "Name",
        :s3_url => "S3 Url",
        :notes => "Notes",
        :user => nil
      )
    ])
  end

  it "renders a list of file_storage_resources" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "S3 Url".to_s, :count => 2
    assert_select "tr>td", :text => "Notes".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
