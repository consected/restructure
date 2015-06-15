require 'rails_helper'

RSpec.describe "masters/show", type: :view do
  before(:each) do
    @master = assign(:master, Master.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
