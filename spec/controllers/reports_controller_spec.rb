# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportsController, type: :controller do
  include ControllerMacros
  include ModelSupport
  include MasterSupport
  include ReportSupport

  before :example do
    create_admin
    create_user
    create_reports
    setup_report_access
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
    expect(res.length).to be >= 1
    expect(res.first).to eq first_rep
  end

  it 'gets a report by numeric or string ID' do
    @test_report = @report1
    setup_report_access

    get :show, params:  { id: @test_report.id }
    expect(response).to have_http_status 200
    expect(assigns(:report)).to eq(@test_report)

    get :show, params:  { id: "#{@test_report.item_type}__#{@test_report.short_name}" }
    expect(response).to have_http_status 200
    expect(assigns(:report)).to eq(@test_report)

    expect { get :show, params: { id: "#{@test_report.item_type}__#{@test_report.short_name}1" } }.to raise_error(ActiveRecord::RecordNotFound)

    get :show, params:  { id: @test_report.item_type.to_s }
    expect(response).to have_http_status 400
  end
end
