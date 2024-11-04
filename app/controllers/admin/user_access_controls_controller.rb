# frozen_string_literal: true

class Admin::UserAccessControlsController < AdminController
  helper_method :has_access_levels, :user_id_options, :role_name_options

  before_action :set_report_to_short_name, only: [:edit]

  protected

  def default_index_order
    Arel.sql "app_type_id asc, resource_type asc, translate(resource_name, '__', 'ZZZZ') asc, #{Admin::UserAccessControl.priority_order}"
  end

  def filters
    rns = Admin::UserAccessControl.resource_names_by_type.clone
    rns.each do |rnt, v|
      rnl = v.map { |rn| rn.split('__')[0..-2].join('__') + '__%' }.uniq.reject { |rn| rn == '__%' }
      rns[rnt] += rnl
      s = rns[rnt]
      rns[rnt] = s.reject { |r| r.include?('__') }.sort + s.select { |r| r.include?('__') }.sort
    end

    {
      app_type_id: Admin::AppType.all_by_name,
      resource_name: rns,
      user_id: User.active.pluck(:id, :email).to_h,
      role_name: Admin::UserRole.active.role_names.sort
    }
  end

  def filters_on
    %i[app_type_id resource_name user_id role_name]
  end

  def has_access_levels
    UserAccessControls.access_levels.map { |m| [m.to_s.captionize, m] }
  end

  def user_id_options
    User.active.map { |u| [u.email, u.id] }
  end

  def role_name_options
    Admin::UserRole.active.role_names_by_app_name
  end

  def extra_field_attributes
    {
      app_type_id: {
        'data-filters-select': '#admin_user_access_control_role_name'
      },
      resource_type: {
        'data-filters-select': '#admin_user_access_control_access'
      }
    }
  end

  def permitted_params
    @permitted_params = %i[id access resource_type resource_name app_type_id user_id role_name disabled]
  end

  # For edit forms on report resources, switch the value to the short name if the long name is being used
  # @return [true]
  def set_report_to_short_name
    if object_instance.resource_type == 'report'
      rn = object_instance.resource_name
      object_instance.resource_name = Report.resource_name_for_named_report(rn) if rn.present? && !(rn.include? '_')
    end
    true
  end
end
