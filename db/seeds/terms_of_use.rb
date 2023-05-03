# frozen_string_literal: true

module Seeds
  module TermsOfUse

    DEFAULT_TEMPLATE_NAME = 'ui update user registration terms default'
    GDPR_TEMPLATE_NAME = 'ui update user registration terms gdpr'

    def self.do_last
      true
    end

    def self.add_values(values)
      values.each do |v|
        res = Admin::MessageTemplate.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_templates
      values = [

        {
          name: DEFAULT_TEMPLATE_NAME,
          template: 'Your checking this box indicates that you have freely agreed to the use of your information as described in the <a href="/info_pages/terms_of_use_non_gdpr#open-in-new-tab">terms of use</a>."',
          template_type: 'content',
          message_type: 'dialog'
        },
        {
          name: GDPR_TEMPLATE_NAME,
          template: 'Your checking this box indicates that you have freely agreed to the use of your personal information and other data as described in the <a href="/info_pages/terms_of_use_gdpr#open-in-new-tab">terms of use</a>.',
          template_type: 'content',
          message_type: 'dialog'
        }

      ]

      add_values values
      Rails.logger.info "#{name} = #{Admin::MessageTemplate.where(name: DEFAULT_TEMPLATE_NAME).length}"
      Rails.logger.info "#{name} = #{Admin::MessageTemplate.where(name: GDPR_TEMPLATE_NAME).length}"
    end

    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Admin::MessageTemplate.where(name: DEFAULT_TEMPLATE_NAME).exists?
        create_templates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end

  end
end
