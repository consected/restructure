# frozen_string_literal: true

class Application
  # Maintains a global (per server instance, so no sharing of data) list of categories of apps that are
  # configured at runtime
  def self.add_to_app_list(list_type, item)
    l = app_list(list_type)
    return if l.include?(item)

    res = l.select { |i| i.name == item.name }
    l << item if res.empty?
  end

  def self.app_list(list_type)
    @@app_list ||= {}
    @@app_list[list_type] ||= []
  end

  def self.version
    @@version ||= File.read('./version.txt').gsub("\n", '')
  end

  def self.server_cache_version
    Rails.cache.fetch('server_cache_version') do
      Time.now.to_f.to_s
    end
  end

  def self.record_error_message(record)
    res = []

    return 'unexpected error' unless record

    record.errors.each do |r, v|
      res << if v
               "#{r} #{v}"
             else
               r.join(' ')
             end
    end

    res.join '; '
  end

  def self.hide_messages
    @@hide_messages ||= [I18n.translate('devise.sessions.signed_in')]
    Rails.logger.info "Hide messages: #{@@hide_messages}"
    @@hide_messages
  end

  def self.refresh_dynamic_defs
    ::ActivityLog.refresh_outdated
    ::DynamicModel.refresh_outdated
    ::ExternalIdentifier.refresh_outdated
  end
end
