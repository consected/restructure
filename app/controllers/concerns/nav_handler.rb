# frozen_string_literal: true

module NavHandler
  extend ActiveSupport::Concern

  include PageLayoutsHelper

  def setup_navs
    return true if request.xhr?

    admin_view = current_admin && is_a?(AdminController)

    @primary_navs = []
    @secondary_navs = []
    @app_type_switches = nil

    @app_type_switches = current_user.accessible_app_types.map { |m| [m.label, m.id] } if current_user
    admin_sub = []
    if current_admin

      admin_sub << { label: 'manage', url: '/', route: '#root' }

      admin_sub << { label: 'password', url: '/admins/edit', extras: { 'data-do-action' => 'admin-change-password' } }
      admin_sub << { label: 'logout_admin', url: '/admins/sign_out', extras: { method: :delete, 'data-do-action' => 'admin-logout' } }

    elsif current_user
      if Admin.active.where(email: current_user.email).first
        admin_sub << { label: 'Admin Login', url: '/admins/sign_in', route: 'admins#sign_in' }
      end
    end

    if current_user
      user_sub = []
      user_sub << { label: 'password', url: '/users/edit', extras: { 'data-do-action' => 'user-change-password' } }
      user_sub << { label: 'logout', url: '/users/sign_out', extras: { method: :delete, 'data-do-action' => 'user-logout' } }
    end
    if current_user || current_admin
      unless admin_sub.empty?
        @secondary_navs << { label: '<span class="glyphicon glyphicon-wrench" title="administrator"></span>', url: '#', sub: admin_sub, extras: { 'data-do-action' => 'show-admin-options' } }
      end
      @secondary_navs << { label: '<span class="glyphicon glyphicon-user" title="user"></span>', url: '#', sub: user_sub, extras: { title: current_email, 'data-do-action' => 'show-user-options' } }
    end

    if current_user
      unless app_config_text(:menu_research_label) == 'none'
        @primary_navs << { label: app_config_text(:menu_research_label, 'Research'), url: '/masters/', route: 'masters#index' }
      end
      if current_user.can? :create_master
        @primary_navs << { label: app_config_text(:menu_create_master_record_label, 'Create Master'), url: '/masters/new', route: 'masters#new' }
      end

      nav_conf = page_layout_panel layout_name: :nav, panel_name: :all

      if nav_conf&.nav&.links
        nav_conf.nav.links.each do |l|
          if l.is_a? String
            url = l
          elsif l.is_a? Hash
            l = l.symbolize_keys
            if l[:resource_type]
              rt = l[:resource_type].to_sym
              rn = l[:resource_name]
              next unless current_user.has_access_to? :access, rt, rn
            end
            url = l[:url]
            label = l[:label]
            @primary_navs << { label: label, url: url }
          end
        end

      end
    end

    if current_user || admin_view
      if (admin_view || current_user&.can?(:view_dashboards)) && current_user&.app_type_id && Admin::PageLayout.app_standalone_layouts(current_user.app_type_id).count > 0
        @primary_navs << { label: 'Dashboards', url: '/page_layouts', route: 'page_layouts#index' }
      end
      if admin_view || current_user.can?(:view_reports)
        @primary_navs << { label: 'Reports', url: '/reports', route: 'reports#index' }
      end
      if admin_view || current_user.can?(:print)
        @primary_navs << { label: 'Print', url: '#body-top', extras: { id: 'print-action', class: 'print-action-button' } }
      end
      if admin_view || current_user.can?(:import_csv)
        @primary_navs << { label: 'Import CSV', url: '/imports', route: 'imports#index' }
      end

    end

    @navbar_ready = true
    res = @primary_navs.select { |n| n[:route] == "#{controller_name}##{action_name}" }
    res.first[:active] = true if res&.first
  end
end
