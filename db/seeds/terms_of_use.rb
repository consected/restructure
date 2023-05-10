# frozen_string_literal: true

module Seeds
  module TermsOfUse

    NEW_USER_DEFAULT_TEMPLATE = 'ui new user registration terms default'
    NEW_USER_GDPR_TEMPLATE = 'ui new user registration terms gdpr'
    UPDATE_USER_DEFAULT_TEMPLATE = 'ui new user registration terms default'
    UPDATE_USER_GDPR_TEMPLATE = 'ui new user registration terms gdpr'

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
          name: NEW_USER_DEFAULT_TEMPLATE,
          template: 'Your checking this box indicates that you have freely agreed to the use of your information as described in the <a href="/info_pages/terms_of_use_non_gdpr#open-in-new-tab">terms of use</a>."',
          template_type: 'content',
          message_type: 'dialog'
        },
        {
          name: NEW_USER_GDPR_TEMPLATE,
          template: 'Your checking this box indicates that you have freely agreed to the use of your personal information and other data as described in the <a href="/info_pages/terms_of_use_gdpr#open-in-new-tab">terms of use</a>.',
          template_type: 'content',
          message_type: 'dialog'
        },
        {
          name: UPDATE_USER_DEFAULT_TEMPLATE,
          template: 'Your checking this box indicates that you have freely agreed to the use of your information as described in the <a href="/info_pages/terms_of_use_non_gdpr#open-in-new-tab">terms of use</a>."',
          template_type: 'content',
          message_type: 'dialog',
          enabled: false
        },
        {
          name: UPDATE_USER_GDPR_TEMPLATE,
          template: 'Your checking this box indicates that you have freely agreed to the use of your personal information and other data as described in the <a href="/info_pages/terms_of_use_gdpr#open-in-new-tab">terms of use</a>.',
          template_type: 'content',
          message_type: 'dialog',
          enabled: false
        }

      ]

      add_values values

      records_count = values.length
      template_names = values.map { |value| value.values_at(:name) }.flatten
      Rails.logger.info "#{name} = should create #{records_count} records: #{Admin::MessageTemplate.where(name: template_names).length == records_count}"
    end

    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Admin::MessageTemplate.where(name: NEW_USER_DEFAULT_TEMPLATE).exists?
        create_templates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end

  end
end
