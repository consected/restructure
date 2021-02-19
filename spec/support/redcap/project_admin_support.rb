module Redcap
  module ProjectAdminSupport
    def valid_attribs
      redcap_project_configs(force_reload: true).dup.first.merge(study: "Study-#{rand 100_000_000_000_000}")
    end

    def list_invalid_attribs
      [
        {
          name: nil,
          server_url: nil
        }
      ]
    end

    def invalid_attribs
      {
        name: nil,
        server_url: nil
      }
    end

    def list_invalid_update_attribs
      list_invalid_attribs
    end

    def invalid_update_attribs
      invalid_attribs
    end

    def new_attribs
      @new_attribs = valid_attribs
    end

    def new_attribs_downcase
      @new_attribs
    end

    def create_items
      setup_redcap_project_admin_configs
      @created_items = Redcap::ProjectAdmin.active.all
    end

    def create_item(project: nil, mocks: true)
      unless project
        project = redcap_project_configs(mocks: mocks).dup.first
        Redcap::ProjectAdmin.where(name: project[:name]).update_all(disabled: true)
      end

      if mocks
        stub_request_project project[:server_url], project[:api_key]
        stub_request_metadata project[:server_url], project[:api_key]
      end

      @project_admin = Redcap::ProjectAdmin.create! current_admin: @admin,
                                                    study: 'Q2',
                                                    name: project[:name],
                                                    api_key: project[:api_key],
                                                    server_url: project[:server_url]
    end
  end
end
