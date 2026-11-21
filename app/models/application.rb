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
      res = Time.now.to_f.to_s
      Rails.logger.warn "Application.server_cache_version changed to #{res}"
      res
    end
  end

  HANDLEBARS_GENERATION_CACHE_KEY = 'handlebars_generation_version'

  # Version identifying the current compiled Handlebars generation. Seeded from
  # server_cache_version, but unlike it, preserved by clear_cache_preserving_generation so that
  # saving a definition or config record does not discard every compiled template.
  def self.handlebars_generation_version
    Rails.cache.fetch(HANDLEBARS_GENERATION_CACHE_KEY) { server_cache_version }
  end

  # Force this process's generation version to the parent's (see server_cache_version=).
  def self.handlebars_generation_version=(value)
    Rails.cache.write(HANDLEBARS_GENERATION_CACHE_KEY, value)
  end

  # Token that changes whenever the whole Rails cache has been cleared, since it is itself
  # discarded by the clear. Lets state that depends on cached fragments (such as prewarm
  # markers) detect that those fragments are cold, even when the generation is preserved.
  def self.cache_epoch
    Rails.cache.fetch('cache_epoch') { SecureRandom.hex(8) }
  end

  # Clear the whole Rails cache, but keep the Handlebars generation version.
  # Not atomic: a process reading between the clear and the write seeds a new version.
  def self.clear_cache_preserving_generation
    generation_version = handlebars_generation_version
    Rails.cache.clear
    Rails.cache.write(HANDLEBARS_GENERATION_CACHE_KEY, generation_version)
  end

  # Force this process's cache to hold a specific server_cache_version (issue #1362) -
  # used to make a spawned process agree with its parent's value even when Rails.cache is
  # not actually shared across processes (e.g. :memory_store), rather than each process
  # independently computing its own random value.
  def self.server_cache_version=(value)
    Rails.cache.write('server_cache_version', value)
  end

  def self.record_error_message(record)
    res = []

    return 'unexpected error' unless record

    record.errors.each do |e|
      r = e.attribute
      v = e.message
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
