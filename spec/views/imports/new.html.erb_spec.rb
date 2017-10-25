require 'rails_helper'

RSpec.describe "imports/new", type: :view do
  before(:each) do
    assign(:import, Import.new(
      :primary_table => "MyString",
      :item_count => 1,
      :filename => "MyString",
      :items => "",
      :user => nil
    ))
  end

  it "renders new import form" do
    render

    assert_select "form[action=?][method=?]", imports_path, "post" do

      assert_select "input#import_primary_table[name=?]", "import[primary_table]"

      assert_select "input#import_item_count[name=?]", "import[item_count]"

      assert_select "input#import_filename[name=?]", "import[filename]"

      assert_select "input#import_items[name=?]", "import[items]"

      assert_select "input#import_user_id[name=?]", "import[user_id]"
    end
  end
end
