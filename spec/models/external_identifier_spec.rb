require 'rails_helper'
require './db/table_generators/external_identifiers_table.rb'

RSpec.describe ExternalIdentifier, type: :model do
  include ModelSupport
  include ExternalIdentifierSupport

  before :all do
    create_admin
    create_user
    r = 'test7'
    @implementation_table_name = "test_external_#{r}_identifiers"
    @implementation_attr_name = "test_#{r}_id"
    unless ActiveRecord::Base.connection.table_exists? @implementation_table_name
      TableGenerators.external_identifiers_table(@implementation_table_name, @implementation_attr_name, true)
    end

  end
  it "has an implementation class for a created external model" do
    # Check if a configured item does actually exist as a usable model
    vals = list_valid_attribs.first

    e = create_item vals

    res = nil
    begin
      res = e.implementation_class.new
    rescue NoMethodError
      puts "Implementation class doesn't appear to have been defined"
    rescue NameError
      puts "Implementation class doesn't appear to have been defined"
    end
    expect(res).not_to be nil

    m = create_master
    c = e.implementation_class
    eid = rand(9999999)

    res = c.create(c.external_id_attribute => eid, master: m)
    expect(res).to be_a c
    expect(res.id).not_to be nil
    expect(res.attributes[c.external_id_attribute]).to eq eid

    res = c.new(c.external_id_attribute => -1, master: m)

    expect(res.save).to be false

  end
end
