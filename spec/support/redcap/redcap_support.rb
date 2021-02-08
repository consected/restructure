module Redcap
  module RedcapSupport
    def setup_redcap_project_admin_configs
      projects = redcap_project_configs

      Redcap::ProjectAdmin.update_all(disabled: true)

      projects.each do |p|
        Redcap::ProjectAdmin.create! current_admin: @admin,
                                     name: p[:name],
                                     api_key: p[:api_key],
                                     server_url: p[:server_url]
      end

      expect(Redcap::ProjectAdmin.active.count).to eq 1
      projects
    end

    # Get project configurations from encrypted credential storage
    def redcap_project_configs
      return @redcap_project_configs if @redcap_project_configs

      rcconf = Rails.application.credentials.redcap
      return unless rcconf

      @redcap_project_configs = rcconf[:projects]
    end
  end
end
