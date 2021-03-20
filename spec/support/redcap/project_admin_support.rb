module Redcap
  module ProjectAdminSupport
    def create_admin_matching_user
      app_type = Admin::AppType.active.find_by_name('ref-data')
      app_type_id = app_type.id
      create_user(nil, '', email: @admin.email) unless @admin.matching_user

      @user = user = @admin.matching_user

      enable_user_app_access app_type.name, user
      user.update!(app_type_id: app_type_id)

      expect(app_type_id).not_to be_nil
      expect(Settings.admin_master).not_to be_nil

      setup_access 'trackers', user: user
      setup_access 'nfs_store__manage__containers', user: user
      setup_access 'nfs_store__manage__stored_files', user: user
      setup_access 'nfs_store__manage__archived_files', user: user
      expect(@admin.matching_user.app_type).not_to be_nil
      expect(@admin.matching_user).to eq user

      user
    end

    def valid_attribs
      create_admin_matching_user
      redcap_project_configs(force_reload: true).dup.first.merge(study: "Study-#{rand 100_000_000_000_000}")
    end

    def list_invalid_attribs
      create_admin_matching_user
      [
        {
          name: nil,
          server_url: nil
        }
      ]
    end

    def invalid_attribs
      create_admin_matching_user
      {
        name: nil,
        server_url: nil
      }
    end

    def list_invalid_update_attribs
      create_admin_matching_user
      list_invalid_attribs
    end

    def invalid_update_attribs
      create_admin_matching_user
      invalid_attribs
    end

    def new_attribs
      create_admin_matching_user
      @new_attribs = valid_attribs
    end

    def new_attribs_downcase
      @new_attribs
    end

    def create_items
      setup_redcap_project_admin_configs
      create_admin_matching_user
      @created_items = Redcap::ProjectAdmin.active.all
    end

    def create_item(project: nil, mocks: true)
      create_admin_matching_user

      unless project
        project = redcap_project_configs(mocks: mocks).dup.first
        Redcap::ProjectAdmin.where(name: project[:name]).update_all(disabled: true)
      end

      if mocks
        stub_request_project project[:server_url], project[:api_key]
        stub_request_metadata project[:server_url], project[:api_key]
      end

      expect(@admin.matching_user.app_type).not_to be_nil

      @project_admin = Redcap::ProjectAdmin.create! current_admin: @admin,
                                                    study: 'Q2',
                                                    name: project[:name],
                                                    api_key: project[:api_key],
                                                    server_url: project[:server_url]
    end
  end
end
