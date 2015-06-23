require 'rails_helper'

RSpec.describe "colleges/new", type: :view do
  before(:each) do
    assign(:college, College.new(
      :name => "MyString",
      :synonym_for_id => 1
    ))
  end

  it "renders new college form" do
    render

    assert_select "form[action=?][method=?]", colleges_path, "post" do

      assert_select "input#college_name[name=?]", "college[name]"

      assert_select "input#college_synonym_for_id[name=?]", "college[synonym_for_id]"
    end
  end
end
