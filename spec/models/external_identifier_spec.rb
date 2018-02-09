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
      TableGenerators.external_identifiers_table(@implementation_table_name, true, @implementation_attr_name)
    end

  end

  it "validates new configurations" do
    # Check if a configured item does actually exist as a usable model
    vals = list_valid_attribs.first

    vals[:name] = @implementation_table_name
    vals[:external_id_attribute] = @implementation_attr_name
    e = create_item vals
    expect(e.disabled).to be false

    # No duplicate names
    new_vals = list_valid_attribs.last.dup
    new_vals[:name] = vals[:name]
    new_vals[:disabled] = false

    expect {
      create_item new_vals, nil, true
    }.to raise_error(ActiveRecord::RecordInvalid)

    # No duplicate external_id_attribute
    new_vals = list_valid_attribs.last.dup

    unless ActiveRecord::Base.connection.table_exists? new_vals[:name]
      TableGenerators.external_identifiers_table(new_vals[:name], true, @implementation_attr_name)
    end
    new_vals[:external_id_attribute] = vals[:external_id_attribute]
    new_vals[:disabled] = false
    expect {
      create_item new_vals, nil, true
    }.to raise_error(ActiveRecord::RecordInvalid)

  end

  it "has an implementation class for a created external model" do
    ExternalIdentifier.active.each do |e|
      e.disabled = true
      e.current_admin = @admin
      e.save!
    end
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

    expect(@user.has_access_to? :create, :table, @implementation_table_name).to be_truthy

    eid = rand(9999999)
    m.current_user = @user
    res = c.new(c.external_id_attribute => eid, master: m)

    res.save
    expect(res).to be_a c
    expect(res.id).not_to be nil
    expect(res.attributes[c.external_id_attribute]).to eq eid

    # Ensure it fails if trying to add a bad ID
    res = c.new(c.external_id_attribute => -1, master: m)

    expect(res.save).to be false

  end

  it "allows player records to referenced using the external ID" do
    ExternalIdentifier.active.each do |e|
      e.disabled = true
      e.current_admin = @admin
      e.save!
    end
    # Create an external identifier implementation
    vals = list_valid_attribs.first
    e = create_item vals

    # Create some master records to allow fair testing
    create_master
    m = create_master
    create_master

    # Create an external identifier ID record
    c = e.implementation_class
    eid = rand(9999999)
    m.current_user = @user
    res = c.new(c.external_id_attribute => eid, master: m)
    res.save
    expect(res.id).not_to be nil

    # Attempt to find the master
    found = Master.find_with_alternative_id(vals[:external_id_attribute], eid)
    expect(found).to eq m



  end

end
