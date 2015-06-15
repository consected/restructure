require 'rails_helper'

RSpec.describe "pages/edit", type: :view do
  before(:each) do
    @page = assign(:page, Page.create!(
      :index => "MyString",
      :show => "MyString"
    ))
  end

  it "renders the edit page form" do
    render

    assert_select "form[action=?][method=?]", page_path(@page), "post" do

      assert_select "input#page_index[name=?]", "page[index]"

      assert_select "input#page_show[name=?]", "page[show]"
    end
  end
end
