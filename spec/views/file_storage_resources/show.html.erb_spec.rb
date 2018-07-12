require 'rails_helper'

RSpec.describe "file_storage_resources/show", type: :view do
  before(:each) do
    @file_storage_resource = assign(:file_storage_resource, FileStorageResource.create!(
      :name => "Name",
      :s3_url => "S3 Url",
      :notes => "Notes",
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/S3 Url/)
    expect(rendered).to match(/Notes/)
    expect(rendered).to match(//)
  end
end
