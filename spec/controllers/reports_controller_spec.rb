require 'rails_helper'

RSpec.describe ReportsController, type: :controller do

  include ControllerMacros
  include ModelSupport
  include MasterSupport

  before :all do
    create_admin
    create_user
    sql = "select * from item_flags if1\r\ninner join item_flag_names ifn\r\non if1.item_flag_name_id = ifn.id"

    r = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: "", sql: sql, search_attrs: "",  disabled: false, report_type: "regular_report", auto: false, searchable: true, position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report, resource_name: r.name, current_admin: @admin

    Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: "", sql: sql, search_attrs: "",  disabled: false, report_type: "regular_report", auto: false, searchable: true, position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report, resource_name: r.name, current_admin: @admin

  end

  before_each_login_user

  def setup_report_access
    first_rep = Report.active.searchable.first
    expect(first_rep).to be_a Report

    unless @user.can? :view_reports, :general
      Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :general, resource_name: :view_reports, current_admin: @admin
    end

    unless @user.can? first_rep.name, :report
      Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report, resource_name: first_rep.name, current_admin: @admin
    end

    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 1
    expect(res.first).to eq first_rep
    @test_report = first_rep
  end

  it "gets a report by numeric or string ID" do

    setup_report_access

    get :show, {:id => @test_report.id}
    expect(response).to have_http_status 200
    expect(assigns(:report)).to eq(@test_report)

    get :show, {:id => "#{@test_report.item_type}__#{@test_report.short_name}"}
    expect(response).to have_http_status 200
    expect(assigns(:report)).to eq(@test_report)


    get :show, {:id => "#{@test_report.item_type}__#{@test_report.short_name}1"}
    expect(response).to have_http_status 404

    get :show, {:id => "#{@test_report.item_type}"}
    expect(response).to have_http_status 400

  end

end
