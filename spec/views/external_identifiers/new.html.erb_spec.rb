require 'rails_helper'

RSpec.describe "external_identifiers/new", type: :view do
  before(:each) do
    assign(:external_identifier, ExternalIdentifier.new(
      :name => "MyString",
      :label => "MyString",
      :external_id_attribute => "MyString",
      :external_id_view_formatter => "MyString",
      :prevent_edit => false,
      :pregenerate_ids => false,
      :admin => nil
    ))
  end

  it "renders new external_identifier form" do
    render

    assert_select "form[action=?][method=?]", external_identifiers_path, "post" do

      assert_select "input#external_identifier_name[name=?]", "external_identifier[name]"

      assert_select "input#external_identifier_label[name=?]", "external_identifier[label]"

      assert_select "input#external_identifier_external_id_attribute[name=?]", "external_identifier[external_id_attribute]"

      assert_select "input#external_identifier_external_id_view_formatter[name=?]", "external_identifier[external_id_view_formatter]"

      assert_select "input#external_identifier_prevent_edit[name=?]", "external_identifier[prevent_edit]"

      assert_select "input#external_identifier_pregenerate_ids[name=?]", "external_identifier[pregenerate_ids]"

      assert_select "input#external_identifier_admin_id[name=?]", "external_identifier[admin_id]"
    end
  end
end
