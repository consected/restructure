require 'rails_helper'

RSpec.describe "protocols/show", type: :view do
  before(:each) do
    @protocol = assign(:protocol, Protocol.create!(
      :name => "Name",
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
  end
end
