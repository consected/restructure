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

end
