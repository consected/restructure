require 'rails_helper'

RSpec.describe "pages/new", type: :view do
  before(:each) do
    assign(:page, Page.new(
      :index => "MyString",
      :show => "MyString"
    ))
  end

  it "renders new page form" do
    render

    assert_select "form[action=?][method=?]", pages_path, "post" do

      assert_select "input#page_index[name=?]", "page[index]"

      assert_select "input#page_show[name=?]", "page[show]"
    end
  end
end
