require 'rails_helper'

RSpec.describe "sub_processes/show", type: :view do
  before(:each) do
    @sub_process = assign(:sub_process, SubProcess.create!(
      :name => "Name",
      :disabled => false,
      :protocol => nil,
      :admin => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
