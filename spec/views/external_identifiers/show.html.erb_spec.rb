require 'rails_helper'

RSpec.describe "external_identifiers/show", type: :view do
  before(:each) do
    @external_identifier = assign(:external_identifier, ExternalIdentifier.create!(
      :name => "Name",
      :label => "Label",
      :external_id_attribute => "External Id Attribute",
      :external_id_view_formatter => "External Id View Formatter",
      :prevent_edit => false,
      :pregenerate_ids => false,
      :admin => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Label/)
    expect(rendered).to match(/External Id Attribute/)
    expect(rendered).to match(/External Id View Formatter/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(//)
  end
end
