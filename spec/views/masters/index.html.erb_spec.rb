require 'rails_helper'

RSpec.describe "masters/index", type: :view do
  before(:each) do
    assign(:masters, [
      Master.create!(),
      Master.create!()
    ])
  end

  it "renders a list of masters" do
    render
  end
end
