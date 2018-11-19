module NavHandler
  extend ActiveSupport::Concern

  def setup_navs

    return true if request.xhr?

    admin_view = current_admin && self.is_a?(AdminController)

    @primary_navs = []
    @secondary_navs = []
    @app_type_switches = nil

    if current_user
      @app_type_switches = Admin::AppType.all_available_to(current_user).map {|m| [m.label, m.id]}
    end
    admin_sub = []
    if current_admin

      admin_sub << {label: 'manage', url: '/', route: '#root'}

      admin_sub << {label: 'password', url: "/admins/edit", extras: {'data-do-action' => 'admin-change-password'}}
      admin_sub << {label: 'logout_admin', url: "/admins/sign_out", extras: {method: :delete, 'data-do-action' => 'admin-logout'}}

    elsif current_user
      admin_sub << {label: 'Admin Login', url: '/admins/sign_in', route: 'admins#sign_in', } if Admin.active.where(email: current_user.email).first
    end

    if current_user
      user_sub = []
      user_sub << {label: 'password', url: "/users/edit", extras: {'data-do-action' => 'user-change-password'}}
      user_sub << {label: 'logout', url: "/users/sign_out", extras: {method: :delete, 'data-do-action' => 'user-logout'}}
    end
    if current_user  || current_admin
      @secondary_navs << {label: '<span class="glyphicon glyphicon-wrench" title="administrator"></span>', url: "#", sub: admin_sub, extras: {'data-do-action' => 'show-admin-options'}} if admin_sub.length > 0
      @secondary_navs << {label: '<span class="glyphicon glyphicon-user" title="user"></span>', url: "#", sub: user_sub, extras: {title: current_email, 'data-do-action' => 'show-user-options'}}
    end


    if current_user
      @primary_navs << {label: app_config_text(:menu_research_label, "Research"), url: '/masters/', route: 'masters#index'} unless app_config_text(:menu_research_label) == 'none'
      @primary_navs << {label: app_config_text(:menu_create_master_record_label, "Create Master"), url: '/masters/new', route: 'masters#new'}  if current_user.can? :create_master
    end

    if current_user || admin_view
      @primary_navs << {label: 'Reports', url: '/reports', route: 'reports#index'} if admin_view || current_user.can?(:view_reports)
      @primary_navs << {label: 'Print', url: '#body-top', extras: {id: 'print-action', class: 'print-action-button'}} if admin_view || current_user.can?(:print)
      @primary_navs << {label: 'Import CSV', url: '/imports', route: 'imports#index'}  if admin_view || current_user.can?(:import_csv)

    end


    @navbar_ready = true
    res  = @primary_navs.select {|n| n[:route] == "#{controller_name}##{action_name}" }
    res.first[:active] = true if res && res.first

  end
end
