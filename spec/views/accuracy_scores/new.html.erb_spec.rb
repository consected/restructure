require 'rails_helper'

RSpec.describe "accuracy_scores/new", type: :view do
  before(:each) do
    assign(:accuracy_score, AccuracyScore.new(
      :name => "MyString",
      :value => 1,
      :admin => nil
    ))
  end

  it "renders new accuracy_score form" do
    render

    assert_select "form[action=?][method=?]", accuracy_scores_path, "post" do

      assert_select "input#accuracy_score_name[name=?]", "accuracy_score[name]"

      assert_select "input#accuracy_score_value[name=?]", "accuracy_score[value]"

      assert_select "input#accuracy_score_admin_id[name=?]", "accuracy_score[admin_id]"
    end
  end
end
