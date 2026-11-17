# frozen_string_literal: true

module Seeds
  module NfsStorePreparedDownloadNotifications
    def self.do_last
      true
    end

    def self.setup
      templates = [
        { name: 'server prepared download ready',
          template: '<p>Your requested files are ready to download.</p><p><a href="{{extra_substitutions.download_link}}">Download your files</a></p><p>This link expires at {{extra_substitutions.expires_at}}.</p>',
          template_type: 'content', message_type: 'email' },
        { name: 'server prepared download failed',
          template: '<p>We could not prepare your requested files. Please try your download request again.</p>',
          template_type: 'content', message_type: 'email' }
      ]

      templates.each do |attributes|
        existing = Admin::MessageTemplate.where(name: attributes[:name], template_type: attributes[:template_type],
                                                message_type: attributes[:message_type])
        if existing.exists?
          existing.each do |template|
            next unless template.admin&.id == Seeds.auto_admin.id && template.template != attributes[:template]

            template.update!(template: attributes[:template], current_admin: Seeds.auto_admin)
          end
        else
          Admin::MessageTemplate.create!(attributes.merge(current_admin: Seeds.auto_admin))
        end
      end
    end
  end
end
