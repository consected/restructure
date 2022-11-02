# frozen_string_literal: true

module NavHandler
  extend ActiveSupport::Concern

  include PageLayoutsHelper

  def setup_navs
    return true if request.xhr?

    admin_view = current_admin && (is_a?(AdminController) || controller_name == 'pages' && action_name == 'index')

    @primary_navs = []
    @app_type_switches = nil

    setup_secondary_navs

    if current_user
      unless app_config_text(:menu_research_label) == 'none'
        @primary_navs << { label: app_config_text(:menu_research_label, 'Research'), url: '/masters/',
                           route: 'masters#index' }
      end

      if current_user.can? :create_master
        @primary_navs << { label: app_config_text(:menu_create_master_record_label, 'Create Master'),
                           url: '/masters/new', route: 'masters#new' }
      end

      setup_page_layout_navs
    end

    if current_user || admin_view
      if (admin_view || current_user&.can?(:view_dashboards)) && standalone_layouts?
        @primary_navs << { label: app_config_text(:menu_dashboards_label, 'Dashboards'), url: '/page_layouts',
                           route: 'page_layouts#index' }
      end
      if admin_view || current_user.can?(:view_reports)
        @primary_navs << { label: app_config_text(:menu_reports_label, 'Reports'), url: '/reports',
                           route: 'reports#index' }
      end
      if admin_view || current_user.can?(:print)
        @primary_navs << { label: 'Print', url: '#body-top',
                           extras: { id: 'print-action', class: 'print-action-button' } }
      end
      if admin_view || current_user.can?(:import_csv)
        @primary_navs << { label: 'Import CSV', url: imports_imports_path, route: 'imports#index' }
      end

    end

    highlight_current_action

    @navbar_ready = true
  end

  def setup_secondary_navs
    @secondary_navs = []

    admin_sub = []
    user_sub = []

    setup_admin_sub_nav(admin_sub)
    setup_user_sub_nav(user_sub)

    help_url = app_config_text(:help_index_path, help_index_path(display_as: :embedded))

    help_extras = if help_url.index('http') == 0
                    { target: 'help-page' }
                  else
                    {
                      'data-remote': 'true',
                      'data-toggle': 'uncollapse',
                      'data-target': '#help-sidebar',
                      'data-working-target': '#help-sidebar-body'
                    }
                  end

    @secondary_navs << {
      label: '<span class="glyphicon glyphicon-question-sign" title="help"></span>',
      url: help_url,
      extras: help_extras
    }

    return unless current_user || current_admin

    unless admin_sub.empty?

      @secondary_navs << {
        label: '<span class="glyphicon glyphicon-wrench" title="administrator"></span>',
        url: '#',
        sub: admin_sub,
        extras: { 'data-do-action' => 'show-admin-options' }
      }
    end

    @secondary_navs << {
      label: '<span class="glyphicon glyphicon-user" title="user"></span>',
      url: '#',
      sub: user_sub,
      extras: { title: current_email, 'data-do-action' => 'show-user-options' }
    }
  end

  def setup_page_layout_navs
    nav_conf = page_layout_panel layout_name: :nav, panel_name: %i[all page], set_of: %i[nav links]

    return unless nav_conf

    nav_conf.each do |l|
      next unless l.is_a? Hash

      l = l.symbolize_keys
      if l[:resource_type]
        rt = l[:resource_type].to_sym
        rn = l[:resource_name]
        begin
          next unless current_user.has_access_to? :access, rt, rn
        rescue StandardError => e
          logger.warn "Bad resource name or type specified: #{e}"
          next
        end
      end
      url = l[:url]
      label = l[:label]
      icon = l[:icon]
      @primary_navs << { label: label, url: url, icon: icon }
    end
  end

  def setup_admin_sub_nav(admin_sub)
    if current_admin
      admin_sub << { label: 'manage', url: '/', route: '#root' }
      admin_sub << { label: 'admin password', url: edit_admin_registration_path,
                     extras: { 'data-do-action' => 'admin-change-password' } }
      admin_sub << { label: 'logout admin', url: '/admins/sign_out',
                     extras: { method: :delete, 'data-do-action' => 'admin-logout' } }
    elsif current_user && Admin.for_user(current_user)
      admin_sub << { label: 'Admin Login', url: '/admins/sign_in', route: 'admins#sign_in' }
    end
  end

  def setup_user_sub_nav(user_sub)
    return unless current_user

    @app_type_switches = current_user.accessible_app_types
                                     .map { |m| [m.label, m.id] }
                                     .sort { |a, b| a.first <=> b.first }

    user_sub << { label: 'user profile', url: '/user_profile' }
    user_sub << { label: 'notifications', url: '/reports/user__my_notifications' }
    user_sub << { label: "#{current_admin ? 'user ' : ''}password", url: '/users/edit',
                  extras: { 'data-do-action' => 'user-change-password' } }
    user_sub << { label: 'logout', url: '/users/sign_out',
                  extras: { method: :delete, 'data-do-action' => 'user-logout' } }
  end

  def standalone_layouts?
    current_user&.app_type_id && Admin::PageLayout.app_standalone_layouts(current_user.app_type_id).count > 0
  end

  def highlight_current_action
    res = @primary_navs.find { |n| n[:route] == "#{controller_name}##{action_name}" }
    return unless res

    res[:active] = true
  end
end
