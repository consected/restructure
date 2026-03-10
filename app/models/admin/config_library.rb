# frozen_string_literal: true

class Admin::ConfigLibrary < Admin::AdminBase
  self.table_name = 'config_libraries'
  include AdminHandler
  include Dynamic::VersionHandler

  def self.valid_formats
    %w[yaml html markdown sql]
  end

  validates :name, presence: true
  validates :format, presence: true
  validates :format, inclusion: { in: valid_formats }
  validate :unique_library
  validate :valid_options

  after_commit :refresh_dependencies

  def self.content_named(category, name, format: nil)
    l = where(name:, category:, format:).first

    unless l
      raise FphsException, "No config library in category #{category} named #{name} with format #{format || '(nil)'}"
    end

    l.options
  end

  # Directly substitute the library configurations into the supplied text
  # @param text [String] text that will be updated. Be sure to pass an unfrozen string
  # @param format [Symbol] :yaml or :sql
  # @return [Array] list of Admin::ConfigLibrary instances that were substituted in
  def self.make_substitutions!(text, format)
    return unless text

    if format == :yaml
      prefix = '# '
    elsif format == :sql
      prefix = '-- '
      direct_sub = true
    end

    reg = /#{prefix}@library\s+([^\s]+)\s+([^\s]+)\s*$/
    res = text.match reg
    all_libs = []

    while res
      category = res[1].strip
      name = res[2].strip
      lib = Admin::ConfigLibrary.where(category:, name:, format:).first
      all_libs << lib
      if direct_sub
        text.gsub!(res[0], lib.options || '')
      else
        text.gsub!(res[0], '')
      end
      res = text.match reg
    end

    all_libs
  end

  def is_yaml?
    self.format.to_s == 'yaml'
  end

  def parsed
    if content.present? && is_yaml?
      YAML.safe_load(c)
    else
      {}
    end
  end

  # Find all active definitions that reference this config library
  # via `# @library category name` in their options text.
  # Searches ActivityLog, DynamicModel, ExternalIdentifier, and ConfigLibrary definitions.
  # @return [Array<Hash>] array of hashes with :type, :id, :name, :admin_path keys
  def referenced_by
    refs = []
    library_ref = "# @library #{category} #{name}"

    ActivityLog.active.each do |item|
      text = item.options_text
      next unless text&.include?(library_ref)

      refs << {
        type: 'ActivityLog',
        id: item.id,
        name: item.name,
        resource_name: item.resource_name,
        admin_path: "/admin/activity_logs?filter[id]=#{item.id}&perform_action=edit"
      }
    end

    DynamicModel.active.each do |item|
      text = item.options_text
      next unless text&.include?(library_ref)

      refs << {
        type: 'DynamicModel',
        id: item.id,
        name: item.name,
        resource_name: item.resource_name,
        admin_path: "/admin/dynamic_models?filter[id]=#{item.id}&perform_action=edit"
      }
    end

    ExternalIdentifier.active.each do |item|
      text = item.options_text
      next unless text&.include?(library_ref)

      refs << {
        type: 'ExternalIdentifier',
        id: item.id,
        name: item.name,
        resource_name: item.resource_name,
        admin_path: "/admin/external_identifiers?filter[id]=#{item.id}&perform_action=edit"
      }
    end

    Admin::ConfigLibrary.active.where.not(id:).each do |item|
      next unless item.options&.include?(library_ref)

      refs << {
        type: 'ConfigLibrary',
        id: item.id,
        name: "#{item.category} - #{item.name}",
        resource_name: nil,
        admin_path: "/admin/config_libraries?filter[id]=#{item.id}&perform_action=edit"
      }
    end

    refs
  end

  private

  def unique_library
    l = self.class.active.where(name:, category:, format: self.format).first
    return unless l && l.id != id

    errors.add :name, "and format must be unique. Name: #{name}, category: #{category}, format: #{self.format}"
  end

  def refresh_dependencies
    return unless self.format.to_s == 'yaml'

    ms = []

    ActivityLog.active.each do |a|
      cl = OptionConfigs::ActivityLogOptions.config_libraries a
      ms << a if cl.include? self
    end

    DynamicModel.active.each do |a|
      cl = OptionConfigs::DynamicModelOptions.config_libraries a
      ms << a if cl.include? self
    end

    ExternalIdentifier.active.each do |a|
      cl = OptionConfigs::ExternalIdentifierOptions.config_libraries a
      ms << a if cl.include? self
    end

    ms.each(&:force_option_config_parse)
  end

  def valid_options
    return if options.blank?

    # Allow the libraries a library depends on to be specified
    # This doesn't load them, but does allow validations to pass
    # when saving or importing config libraries that use
    # yaml anchor definitions from other libraries, which would
    # otherwise be specified in the dynamic definition that is using the library
    new_options = OptionConfigs::ExtraOptions.include_libraries(options)

    YAML.safe_load(new_options, aliases: true)
  end
end
