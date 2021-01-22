# frozen_string_literal: true

module ReportSupport
  def create_reports
    @report_sql = sql = "select * from item_flags if1\r\ninner join item_flag_names ifn\r\non if1.item_flag_name_id = ifn.id"

    @report1 = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: '', sql: sql,
                             search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: true,
                             position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: 'type-1')
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: @report1.alt_resource_name, current_admin: @admin

    @report2 = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: '', sql: sql,
                             search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: true,
                             position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: 'type-1')
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: @report2.alt_resource_name, current_admin: @admin

    @report3 = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: '', sql: sql,
                             search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: false,
                             position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: 'type-2')
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: @report3.alt_resource_name, current_admin: @admin
  end

  def check_reports_accessible
    rn = @report1.alt_resource_name

    expect(@user.can?(:view_reports)).to be_truthy
    expect(@user.has_access_to?(:read, :report, rn)).to be_truthy

    expect(User.find_by_sql([@report_sql]).length).to be > 0
  end
end
