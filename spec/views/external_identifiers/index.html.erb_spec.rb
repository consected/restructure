require 'rails_helper'

RSpec.describe "external_identifiers/index", type: :view do
  before(:each) do
    assign(:external_identifiers, [
      ExternalIdentifier.create!(
        :name => "Name",
        :label => "Label",
        :external_id_attribute => "External Id Attribute",
        :external_id_view_formatter => "External Id View Formatter",
        :prevent_edit => false,
        :pregenerate_ids => false,
        :admin => nil
      ),
      ExternalIdentifier.create!(
        :name => "Name",
        :label => "Label",
        :external_id_attribute => "External Id Attribute",
        :external_id_view_formatter => "External Id View Formatter",
        :prevent_edit => false,
        :pregenerate_ids => false,
        :admin => nil
      )
    ])
  end

  it "renders a list of external_identifiers" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Label".to_s, :count => 2
    assert_select "tr>td", :text => "External Id Attribute".to_s, :count => 2
    assert_select "tr>td", :text => "External Id View Formatter".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
