require 'rails_helper'

RSpec.describe "accuracy_scores/edit", type: :view do
  before(:each) do
    @accuracy_score = assign(:accuracy_score, AccuracyScore.create!(
      :name => "MyString",
      :value => 1,
      :admin => nil
    ))
  end

  it "renders the edit accuracy_score form" do
    render

    assert_select "form[action=?][method=?]", accuracy_score_path(@accuracy_score), "post" do

      assert_select "input#accuracy_score_name[name=?]", "accuracy_score[name]"

      assert_select "input#accuracy_score_value[name=?]", "accuracy_score[value]"

      assert_select "input#accuracy_score_admin_id[name=?]", "accuracy_score[admin_id]"
    end
  end
end
