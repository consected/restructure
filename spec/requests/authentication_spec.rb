# frozen_string_literal: true

require 'rails_helper'

describe 'user and admin authentication' do
  include MasterSupport
  include ModelSupport

  before :each do
    seed_database
    expect(ActivityLog.active.length).to be > 0
    expect(defined?(ActivityLog::PlayerContactPhone) && ActivityLog::PlayerContactPhone.is_a?(Class)).to be true
  end

  # Prepare a list of URLs to test

  before(:each) do
    # Handle devise URLs explicitly as users and admins
    # Also handle explicit redirections to home with :redirect_home
    special_urls = { '/admins/edit' => :admins, '/users/edit' => :users, '/admins/:id' => :admins,
                     '/users/:id' => :users, '/admins/sign_out' => :redirect_home, '/users/sign_out' => :redirect_home,
                     '/admins/test_otp' => :redirect_home, '/admins/show_otp' => :redirect_home,
                     '/users/test_otp' => :redirect_home, '/users/show_otp' => :redirect_home,
                     '/help/:library/:section/:subsection' => :not_authorized }

    @url_list = Rails.application.routes.routes.map do |r|
      url = r.path.spec.to_s
      method = nil
      rm = r.constraints[:request_method].to_s

      case rm
      when '(?-mix:^POST$)'
        method = :post
      when '(?-mix:^GET$)'
        method = :get
      when '(?-mix:^PATCH$)'
        method = :patch
      when '(?-mix:^PUT$)'
        method = :put
      when '(?-mix:^DELETE$)'
        method = :delete
      when nil || ''
        method = r.verb.downcase.to_sym
      else
        raise "Unrecognized method (#{rm}) for #{url}"
      end

      url = url.gsub('(.:format)', '')
      rcont = special_urls[url] || r.defaults[:controller]

      res = url.gsub(':item_controller', 'player_infos').gsub(%r{:.+?/}, "#{rand(100_000)}/").gsub(/:.+?$/,
                                                                                                   rand(100_000).to_s)

      { url: res, method: method, controller: rcont, orig_url: url }
    end
  end

  # Check for appropriate redirects to user or admin sign in pages when not logged in
  # This scenario tests all available routes, unless they are listed in the skip_urls list
  # An added benefit to this test is that routes that do not have associated actions (or controllers)
  # will cause a failure, ensuring that route definitions are appropriately limited to avoid 500 errors
  # rather than more correct 404 errors
  it 'redirects to user login page for all paths when not logged in' do
    skip_urls = ['/admins/sign_in', '/users/sign_in', '/child_error_reporter']
    skip_controllers = ['help']

    admin_controllers = %w[admin/accuracy_scores admin/colleges admin/general_selections admin/item_flag_names
                           admin/manage_admins admin/manage_users
                           admin/protocol_events admin/protocols admin/sub_processes admins
                           admin/dynamic_models admin/sage_assignments admin/reports admin/external_links
                           admin/activity_logs admin/external_identifiers admin/external_identifier_details
                           admin/app_types admin/user_access_controls
                           admin/app_configurations admin/message_notifications admin/message_templates
                           admin/job_reviews admin/page_layouts admin/user_roles admin/nfs_store/filter/filters
                           admin/role_descriptions
                           users/contact_infos admin/config_libraries admin/server_info
                           redcap/project_admins redcap/client_requests redcap/data_dictionaries]

    @url_list.each do |url|
      next unless url[:controller] && !skip_urls.include?(url[:url]) && !skip_controllers.include?(url[:controller])

      begin
        case url[:method]
        when :get
          get url[:url]
        when :patch
          patch url[:url]
        when :put
          put url[:url]
        when :delete
          delete url[:url]
        when :post
          post url[:url]
        end

        if url[:controller] == :not_authorized
          expect(response).to have_http_status 401
          break
        end

        expect(response).to have_http_status(302), "expected a redirect for #{url}. Got #{response.status}"

        if url[:controller] == :redirect_home
          expect(response).to redirect_to('http://www.example.com/'),
                              "expected a redirect to home page for #{url} using controller #{url[:controller]} for original url #{url[:orig_url]}. Got #{response.inspect}"
        elsif admin_controllers.include?(url[:controller].to_s)
          expect(response).to redirect_to('http://www.example.com/admins/sign_in'),
                              "expected a redirect to admins/sign_in for #{url} using controller #{url[:controller]} for original url #{url[:orig_url]}. Got #{response.inspect}"
        else
          expect(response).to redirect_to('http://www.example.com/users/sign_in'),
                              "expected a redirect to users/sign_in for #{url} using controller #{url[:controller]} for original url #{url[:orig_url]}. (#{url[:url]}) Got #{response.inspect}"
        end
      rescue AbstractController::ActionNotFound
        Rails.logger.info "Action not defined. Skipping #{url.inspect}"
      end
    end
  end
end
