require 'rails_helper'

RSpec.describe "colleges/edit", type: :view do
  before(:each) do
    @college = assign(:college, College.create!(
      :name => "MyString",
      :synonym_for_id => 1
    ))
  end

  it "renders the edit college form" do
    render

    assert_select "form[action=?][method=?]", college_path(@college), "post" do

      assert_select "input#college_name[name=?]", "college[name]"

      assert_select "input#college_synonym_for_id[name=?]", "college[synonym_for_id]"
    end
  end
end
