# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Report, type: :model do
  include ModelSupport
  include ReportSupport

  before :example do
    create_admin
    create_user
    create_reports
  end

  it 'allows a user to see certain reports, based on access controls' do
    create_admin
    create_user

    res = Report.active.searchable
    expect(res.length).to be > 0

    # Ensure general report usage is not allowed
    rs = Admin::UserAccessControl.active.where resource_type: :report
    rs.update_all(disabled: true)

    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 0

    first_rep = Report.active.searchable.first
    expect(first_rep).to be_a Report
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: first_rep.name, current_admin: @admin

    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 1
    expect(res.first).to eq first_rep

    Admin::UserAccessControl.create! app_type: @user.app_type, user: @user, access: nil, resource_type: :report,
                                     resource_name: first_rep.name, current_admin: @admin
    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 0
  end

  # Issue #1011: get_query_count? decouples count fetching from the auto flag.
  # A report should only auto-fetch query counts when get_query_count option is true,
  # regardless of the auto column value.
  describe '#get_query_count?' do
    it 'returns false when auto is true but get_query_count is not set' do
      report = @report1
      report.current_admin = @admin
      report.update!(auto: true, options: '')
      expect(report.get_query_count?).to be false
    end

    it 'returns true when get_query_count is set to true' do
      report = @report1
      report.current_admin = @admin
      report.update!(auto: true, options: "list_options:\n  get_query_count: true")
      expect(report.get_query_count?).to be true
    end

    it 'returns false when get_query_count is explicitly set to false' do
      report = @report1
      report.current_admin = @admin
      report.update!(auto: false, options: "list_options:\n  get_query_count: false")
      expect(report.get_query_count?).to be false
    end
  end

  it 'references reports by an item_type__short_name alternative resource name' do
    create_admin
    first_rep = @report1
    expect(first_rep).to be_a Report
    expect(first_rep.short_name).to be_present
    expect(first_rep.item_type).to be_present

    # check downcasing of category in the DB
    first_rep.item_type = first_rep.item_type.captionize
    first_rep.current_admin = @admin
    first_rep.save!
    first_rep = first_rep.reload
    expect(first_rep.item_type).to eq first_rep.item_type.downcase

    Report.find_by_alt_resource_name "#{first_rep.item_type}__#{first_rep.short_name}"
  end
end
