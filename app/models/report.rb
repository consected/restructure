# frozen_string_literal: true

# Report criteria can rely on resources that have not autoloaded. Just make sure
require_dependency 'player_info'
require_dependency 'pro_info'
require_dependency 'player_contact'
require_dependency 'address'
require_dependency 'datadic/user_variable'
class Report < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  # @todo refactor this to be a separate class, or incorporate into Reports::Runner
  include Reports::ReportEditing

  before_validation :downcase_item_type
  before_validation :search_attributes_config_valid
  before_validation :gen_short_name
  validates :report_type, presence: true
  validates :name, presence: true
  validate :valid_short_name?, unless: -> { disabled }
  validate :valid_item_type?, unless: -> { disabled }
  validate :valid_resource_name?, unless: -> { disabled }
  validate :options_valid?, unless: -> { disabled }

  scope :counts, -> { where report_type: 'count' }
  scope :regular, -> { where report_type: 'regular_report' }
  scope :searchable, -> { where(searchable: true).order(position: :asc) }

  ReportTypes = %i[count regular_report search].freeze

  attr_accessor :current_user

  class BadSearchCriteria < FphsException
    def message
      'Bad search criteria were entered. Please check entries and try again.'
    end
  end

  #
  # Class that implements options functionality
  def self.options_provider
    OptionConfigs::ReportOptions
  end

  #
  # Map options field to options_text attribute expected for config libraries
  # @todo - also handle the search attribute configs
  def options_text
    options
  end

  #
  # Attribute containing options to be parsed by the options provider
  # in the admin report definition page
  def self.option_configs_attr
    :sql
  end

  #
  # Get reports that the user has access to in its current app
  # @param [User] user
  # @return [ActiveRecord::Relation] reports
  def self.for_user(user)
    if user.has_access_to?(:read, :report, :_all_reports_)
      all
    else
      ns = []
      all.each do |r|
        ns << r.id if report_available_to_user r, user
      end

      where(id: ns)
    end
  end

  #
  # Find a report based on an alt_resource_name style of "item_type__short_name" where a double underscore
  # acts as the divider between item_type "category" and short_name
  # @param csn [String] must match the pattern yyy__zzz
  # @return [Report] or raises an exception if not found
  def self.find_by_alt_resource_name(csn, nil_for_no_match = nil, ignore_bad_format = nil)
    csn = csn.gsub('___', ' - ')
    parts = csn.split('__')
    raise FphsException, 'Bad item_type__short_name identifier' unless parts.length == 2 || ignore_bad_format

    i = parts.first
    # Allow hyphenated categories to be matched with underscores
    its = [i, i.gsub('_', '-'), i.gsub('_', ' ')].uniq
    its << nil if i == '_default'
    res = where(item_type: its, short_name: parts.last).first
    raise ActiveRecord::RecordNotFound unless res || nil_for_no_match

    res
  end

  #
  # Get the resource name for a report based on the provided human name
  # @param name [String] full name of the report
  # @return [String] short_name for the report
  def self.resource_name_for_named_report(name, item_type = nil)
    res = Report.active.where(name: name)

    res = res.where(item_type: item_type) if item_type

    res.order(updated_at: :desc).first&.alt_resource_name
  end

  #
  # Find a report by id if it is (or represents) an integer, or by
  # alt_resource_name if it represents a string that is not an integer
  # @param [String | Intger] id - find using id as integer or alt_resource_name
  # @return [Report]
  # @raise [ActiveRecord::NotFound] if no match using the appropriate method
  def self.find_by_id_or_resource_name(id)
    num_id = id.to_i
    if num_id > 0
      Report.active.find(num_id)
    else
      Report.active.find_by_alt_resource_name id
    end
  end

  #
  # Does the user have access to run the report?
  # @param [Report] report
  # @param [User] user
  # @return [Boolean]
  def self.report_available_to_user(report, user)
    user.has_access_to?(:read, :report, report.alt_resource_name) || user.has_access_to?(:read, :report, report.name)
  end

  #
  # Equivalent to `HandlesUserBase#can_access?`
  def can_access?(user)
    return true if self.class.report_available_to_user self, user

    user.has_access_to?(:read, :report, :_all_reports_)
  end

  #
  # Generate a list of categories, which are the unique item_type values for active records
  def self.categories
    Report.active.select('distinct item_type').where('item_type is not null').pluck(:item_type)
  end

  #
  # Alias for item_type
  def category
    item_type
  end

  #
  # Parsed search attributes configuration
  # @return [Hash]
  def search_attributes
    @search_attributes ||= search_attributes_config.hash_configuration
  end

  #
  # Does the SQL definition include data reference table substitution strings?
  # @return [boolean]
  def uses_table_subs?
    sql.include?('{{table_name}}') || sql.include?('{{table_fields}}')
  end

  #
  # Set up or return the search attributes config class, for parsing the
  # text attribute #search_attibs.
  # Access configuration attributes directly as:
  #    search_attributes_config[:<param name>].<label | type | default ...>
  def search_attributes_config
    @search_attributes_config ||= OptionConfigs::SearchAttributesConfig.new(self)
  end

  #
  # Simplify access to report running functionality
  # @return [Reports::Runner]
  def runner
    @runner ||= Reports::Runner.new self
  end

  #
  # Set up or return the report options class, parsing the text attribute #options.
  # Access configuration items directly as:
  #    report_options.<view_css | component | list_options ...>
  def report_options(fail_without_exception: nil)
    @report_options ||= OptionConfigs::ReportOptions.new self
  rescue StandardError => e
    return nil if fail_without_exception

    raise e
  end

  def as_json(options = {})
    self.item_type = item_type.downcase if item_type
    self.short_name ||= gen_short_name
    super
  end

  def alt_resource_name
    self.class.alt_resource_name item_type, short_name
  end

  def self.alt_resource_name(item_type, short_name)
    "#{item_type&.id_underscore || '_default'}__#{short_name}".downcase.id_underscore
  end

  # Optionally show a different description in the list
  def list_description
    report_options.list_options.list_description || description
  end

  def gen_short_name
    self.short_name = self.class.gen_short_name(name) if short_name.blank?
  end

  def self.gen_short_name(name)
    name.downcase.id_underscore.gsub(/__+/, '_')
  end

  def self.resource_category
    :report
  end

  private

  def search_attributes_config_valid
    return true if search_attributes_config.valid?

    errors.add :search_attributes,
               'definition can not be parsed. Check the YAML or JSON is valid. ' \
               "#{search_attributes_config.errors.join("\n")}"
  end

  def downcase_item_type
    self.item_type = item_type.downcase if item_type
  end

  # Validate short_name is downcased
  def valid_short_name?
    short_name.id_underscore.downcase == short_name
  end

  # Validate the generated resource_name is not a duplicate
  def valid_resource_name?
    test = { short_name: short_name, item_type: item_type }

    res = self.class.active.where(test)
    return if (res.pluck(:id) - [id]).empty?

    res.each do |res0|
      errors.add :resource_name,
                 "is a duplicate of another report record: (#{name}) #{self} --duplicates-- (#{res0.name}) #{{
                   short_name: res0.short_name, item_type: res0.item_type
                 }} "
    end
  end

  # Validate the item_type to prevent multiple double underscores in resource_name
  def valid_item_type?
    return unless item_type

    parts = item_type.id_underscore.split('__')
    return if parts.length <= 1

    errors.add :item_type,
               'must not use multiple space or punctuation characters between letters: ' \
               "'#{item_type}' becomes #{item_type.id_underscore}"
  end

  def invalidate_cache
    logger.info 'Not invalidating cache for report'
  end

  def options_valid?
    OptionConfigs::ReportOptions.raise_bad_configs(report_options)
  rescue FphsException => e
    errors.add :options, e
  end
end
