require 'rails_helper'
require './db/table_generators/external_identifiers_table.rb'

RSpec.describe Admin::ExternalIdentifiersController, type: :controller do

    include MasterSupport
    include ExternalIdentifierSupport

    def object_class
      ExternalIdentifier
    end
    def item
      @external_identifier
    end

    def edit_form_admin
      @edit_form_admin = "admin/common_templates/_form"
    end

    def saved_item_template
      'admin/common_templates/_item'
    end

    before(:all) do
      seed_database
      @path_prefix = "/admin"

      r = 'test7'
      @implementation_table_name = "test_external_#{r}_identifiers"
      @implementation_attr_name = "test_#{r}_id"
      unless ActiveRecord::Base.connection.table_exists? @implementation_table_name
        TableGenerators.external_identifiers_table(@implementation_table_name, true, @implementation_attr_name)
      end

    end

    before_each_login_admin

    before :each do

      disable_existing_records :all, current_admin: @admin
    end

    it_behaves_like 'a standard admin controller'


    it "returns an error when the table does not exist" do
      r = '7'
      inv = {
        name: "table_doesnt_exist",
        label: "test id #{r}",
        external_id_attribute: "test_#{r}_id",
        min_id: 1,
        max_id: 99999999,
        disabled: false
      }
      post :create, {object_symbol => inv}
      expect(assigns(object_symbol).errors.empty?).not_to be true

    end
end
