require 'rails_helper'

RSpec.describe "colleges/show", type: :view do
  before(:each) do
    @college = assign(:college, College.create!(
      :name => "Name",
      :synonym_for_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/1/)
  end
end
