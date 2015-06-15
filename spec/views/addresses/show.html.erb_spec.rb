require 'rails_helper'

RSpec.describe "addresses/show", type: :view do
  before(:each) do
    @address = assign(:address, Address.create!(
      :master => nil,
      :street => "Street",
      :street2 => "Street2",
      :street3 => "Street3",
      :city => "City",
      :state => "State",
      :zip => "Zip",
      :source => "Source",
      :rank => 1,
      :type => "Type",
      :user => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Street/)
    expect(rendered).to match(/Street2/)
    expect(rendered).to match(/Street3/)
    expect(rendered).to match(/City/)
    expect(rendered).to match(/State/)
    expect(rendered).to match(/Zip/)
    expect(rendered).to match(/Source/)
    expect(rendered).to match(/1/)
    expect(rendered).to match(/Type/)
    expect(rendered).to match(//)
  end
end
