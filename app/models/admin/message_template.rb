# frozen_string_literal: true

class Admin::MessageTemplate < ActiveRecord::Base
  self.table_name = 'message_templates'
  include AdminHandler
  include Formatter::Formatters

  validates :message_type, presence: true
  validates :template_type, presence: true

  scope :content_templates, -> { where template_type: 'content' }
  scope :layout_templates, -> { where template_type: 'layout' }
  scope :dialog_templates, -> { where message_type: 'dialog' }

  HtmlRegEx = /<(p ?.*|br ?.*|div ?.*|ul ?.*|hr ?.*)>/.freeze

  #
  # First matching definition matching name and optional type
  #
  # @param [String|Symbol] name the name to find
  # @param [String|Symbol|nil] type optionally the type to find
  # @return [Admin::MessageTemplate|nil] matching instance
  #
  def self.named(name, type: nil)
    res = where(name: name)
    res = res.where(message_type: type) if type
    res.first
  end

  # Valid message types
  def self.message_types
    %i[email dialog sms]
  end

  # Valid template types
  def self.template_types
    %i[layout content]
  end

  # @return [True|False] is this a layout template type
  #
  def layout_template?
    template_type == 'layout'
  end

  # @return [True|False] is this a content template type
  #
  def content_template?
    template_type == 'content'
  end

  # Simply calls {substitute}
  def substitute(all_content, data: {}, tag_subs: nil, ignore_missing: false)
    self.class.substitute all_content, data: data, tag_subs: tag_subs, ignore_missing: ignore_missing
  end

  #
  # Perform subsititions on the the text, using either a Hash of data or an object item.
  # Provide a tag substitution to be used to enclose the substituted items
  #
  # Substitution text examples:
  # {{select_who}} {{player_info.first_name}} {{user.email}}
  #
  # Formatting directives are also available, following ::
  # {{select_who::uppercase}}
  #
  # Functional directives may also be processed as square brackets
  # Example text:
  # [[shortlink https://footballplayershealth.harvard.edu/join-us/?test_id={{ids.msid}}]]
  #
  # @param all_content [String] the text containing possible {{something.else}} to be substituted
  # @param in_data [Hash | UserBase] represent the substitution data with a Hash or a an object instance
  # @param tag_subs [String] for example 'span class="someclass"'
  # @return [String] resulting text after substitution
  def self.substitute(all_content, data: {}, tag_subs:, ignore_missing: false)
    return unless all_content

    all_content = all_content.dup
    tags = all_content.scan(/{{[0-9a-zA-Z_\.\:]+}}/)

    # Only setup data if there are tags
    sub_data = setup_data(data) unless tags.empty?
    # Replace each tag {{tag}}
    tags.each do |tag_container|
      tag = tag_container[2..-3]
      missing = false

      tagpair = tag.split('.')

      if tagpair.length >= 2
        # For {{tag.attr}} or {{tag.sub.attr}} items, get the association (if needed), then
        # get the actual attribute value

        ref_parts = tagpair[0..-2]
        # Make the current tag just the attribute name, since it may include {{attr::formatting}} to be processed
        tag = tagpair.last
        d = get_assoc(sub_data[:master], ref_parts, sub_data)
      else
        d = sub_data
      end

      # Handle formatting directives, following the ::
      tag_split = tag.split('::')
      tag_name = tag_split.first
      first_format_directive = tag_split[1]
      ignore_missing = :show_blank if first_format_directive == 'ignore_missing'

      unless d&.is_a?(Hash) && (d&.key?(tag_name) || d&.key?(tag_name.to_sym)) || tag.start_with?('embedded_report_')
        if ignore_missing
          d = {}
          missing = true
        else
          raise FphsException, "Data (#{d.class.name}) does not contain the tag #{tag_name} or :#{tag_name}\n#{d || 'data is empty'}"
        end
      end

      tag_value = if missing
                    if ignore_missing == :show_tag
                      "{{#{tag}}}"
                    else
                      ''
                    end
                  else
                    get_tag_value d, tag
                  end

      # Handle the formatting of html tags for tag substitutions, if they have been specified
      if tag_subs
        tag_subs_type = tag_subs.split(' ').first
        tag_value = "<#{tag_subs}>#{tag_value}</#{tag_subs_type}>"
      else
        tag_value = tag_value.to_s
      end

      # Finally, substitute the results into the original text
      all_content.gsub!(tag_container, tag_value)
    end

    # Unless we have requested to show missing tags, check for {{tag}} left in the text, indicating something was not replaced
    if ignore_missing != :show_tag && !all_content.scan(/{{.*}}/).empty?
      raise FphsException, 'Not all the tags were replaced. This suggests there was an error in the markup.'
    end

    tags = all_content.scan(/\[\[[^\]]+\]\]/)

    # Setup the data if it wasn't previously setup and there are tags to replace
    sub_data ||= setup_data(data) unless tags.empty?

    # Replace each tag [[tag]], representing functional directives, such as shortlink production
    tags.each do |tag_container|
      tag = tag_container[2..-3]

      tag_parts = tag.split(' ', 2)
      tag_action = tag_parts.first

      if tag_action == 'shortlink'
        tag_value = handle_shortlink sub_data, tag_parts[1]
      else
        raise FphsException, "Bad message template tag action [[#{tag_action}]] specified"
      end

      # Make the replacement
      all_content.gsub!(tag_container, tag_value) if tag_value
    end

    # Return the resulting text
    all_content
  end

  #
  # When the instance is a layout template, generate substituted text from
  # either a named content template or raw text
  #
  # In the layout template, the text {{main_content}} is replaced with the
  # result of the substituted content template. Any valid tags in the layout
  # template will also be substituted
  #
  # @param [String|Symbol] content_template_name name of content template
  # @param [String] content_template_text raw text to use a template
  # @param [Hash] data simple Hash to pass to #substitute
  # @param [Boolean] ignore_missing defaults to false
  # @return [String] resulting text
  #
  def generate(content_template_name: nil, content_template_text: nil, data: {}, ignore_missing: false)
    raise FphsException, 'Must use a layout template to generate from' unless layout_template?

    if content_template_name
      # Lookup the template based on its name
      content_template = Admin::MessageTemplate.active.content_templates.where(name: content_template_name).first
      raise FphsException, "No content template found with name: #{content_template_name}" unless content_template

      # The raw text is the #template definition
      content_template_text = content_template.template
    elsif !content_template_text
      raise FphsException, 'Either a content_template_name or content_template_text must be specified'
    end

    text = content_template_text.dup

    all_content = template.sub('{{main_content}}', text)
    all_content = substitute all_content, data: data, ignore_missing: ignore_missing

    all_content
  end

  # If the text does not contain any HTML tags, assume it is markdown and format it as HTML
  def self.text_to_html(text)
    return text unless text.is_a? String

    has_html = !text.scan(HtmlRegEx).empty?
    text = Kramdown::Document.new(text).to_html.html_safe unless has_html

    text
  end

  ##### The following methods are not intended for use outside this class ######

  #
  # Get the current tag value from the data, and format it
  # Any number of :: separated formatting operators will be applied in the order the appear
  #
  # @param [Hash] data from {substitute}
  # @param [String] tag_and_operator tag name and optionally formatting operators after ::
  # @return [String] result
  #
  def self.get_tag_value(data, tag_and_operator)
    tagp = tag_and_operator.split('::')
    tag = tagp.first

    if tag.start_with? 'embedded_report_'
      report_name = tag.sub('embedded_report_', '')
      # Find the source item to call the report with
      if data[:original_item].respond_to?(:referring_record) && data[:original_item].referring_record
        list_item = data[:original_item].referring_record
        list_id = list_item.id
      else
        list_item = data[:original_item]
        list_id = list_item[:id]
      end

      list_type = list_item.class.name

      return Reports::Template.embedded_report report_name, list_id, list_type
    end

    orig_val = data[tag] || data[tag.to_sym]
    res = orig_val || ''

    res = formatter_do(res.class, res, current_user: data[:current_user_instance])

    return if res.nil? && tagp[1] != 'ignore_missing'

    # Automatically titleize names
    tagp << 'titleize' if tagp.length == 1 && (tag == 'name' || tag.end_with?('_name'))
    tagp[1..-1].each do |op|
      # NOTE: if additional formatters are added here, they also need matching javascript
      # in _fpa_form_utils.format_subtitution
      if op == 'capitalize'
        res = res.capitalize
      elsif op == 'titleize'
        res = res.titleize
      elsif op == 'uppercase'
        res = res.upcase
      elsif op == 'lowercase'
        res = res.downcase
      elsif op == 'underscore'
        res = res.underscore
      elsif op == 'hyphenate'
        res = res.hyphenate
      elsif op == 'initial'
        res = res.first&.upcase
      elsif op == 'first'
        res = res.first
      elsif op == 'dicom_datetime'
        res = orig_val.strftime('%Y%m%d%H%M%S+0000') if orig_val.respond_to? :strftime
      elsif op == 'dicom_date'
        res = orig_val.strftime('%Y%m%d') if orig_val.respond_to? :strftime
      elsif op == 'join_with_space'
        res = res.join(' ') if res.is_a? Array
      elsif op == 'join_with_comma'
        res = res.join(', ') if res.is_a? Array
      elsif op == 'join_with_semicolon'
        res = res.join('; ') if res.is_a? Array
      elsif op == 'join_with_newline'
        res = res.join("\n") if res.is_a? Array
      elsif op == 'join_with_2newlines'
        res = res.join("\n\n") if res.is_a? Array
      elsif op == 'compact'
        res = res.reject(&:blank?) if res.is_a? Array
      elsif op == 'sort'
        res = res.sort if res.is_a? Array
      elsif op == 'uniq'
        res = res.uniq if res.is_a? Array
      elsif op == 'markdown_list'
        res = '  - ' + res.join("\n  - ") if res.is_a? Array
      elsif op == 'html_list'
        res = '<ul><li>' + res.join("</li>\n  <li>") + '</li></ul>' if res.is_a? Array
      elsif op == 'plaintext'
        res = ActionController::Base.helpers.sanitize(res)
        res = res.gsub("\n", '<br>').html_safe
      elsif op == 'markup'
        res = Kramdown::Document.new(res).to_html.html_safe
      elsif op == 'ignore_missing'
        res ||= ''
      elsif op.to_i != 0
        res = res[0..op.to_i]
      end
    end

    res
  end

  #
  # Setup data for substitutions, working with either a provided Hash
  # or building out more detail with an instance
  #
  # @param [Hash | UserBase] item the baseline data to work with
  # @param [Hash] alt_item an additional Hash item to include
  # @return [Hash] the return data structure
  #
  def self.setup_data(item, alt_item = nil)
    if item.is_a? Hash
      data = item.dup
      data.symbolize_keys!
      master = item[:master]
      master = Master.find(item[:master_id]) if item[:master_id] && !master
    else
      data = item.attributes.dup
      data[:original_item] = item
      data[:alt_item] = alt_item

      if item.respond_to?(:master)
        master = item.master
      elsif item.is_a? Master
        master = item
      end

    end

    # Common constants tags
    data[:base_url] = Settings::BaseUrl
    data[:admin_email] = Settings::AdminEmail
    data[:environment_name] = Settings::EnvironmentName
    data[:password_age_limit] = Settings::PasswordAgeLimit
    data[:password_reminder_days] = Settings::PasswordReminderDays

    # if the referenced item has its own referenced item (much like an activity log might), then get it
    data[:item] = item.item.attributes if item.respond_to?(:item) && item.item.respond_to?(:attributes)

    data[:created_by_user] = nil
    data[:created_by_user_email] = nil

    if item.respond_to?(:created_by_user)
      data[:created_by_user] = item.created_by_user
      data[:created_by_user_email] = item.created_by_user_email
    end

    if master
      data[:master] = master
      data[:master_id] ||= master.id
      # Alternative ids are evaluated as needed
      # Associations are evaluated as needed in the data substitution, to avoid slowing everything down
    end

    iu = item.user if item.respond_to?(:user)
    if iu
      data[:item_user] = iu.attributes
      data[:user_email] = iu.email
      data[:user_preference] = iu.user_preference.attributes
      data[:user_contact_info] = iu.contact_info&.attributes || Users::ContactInfo.new.attributes

    end

    cu = item.current_user if item.respond_to?(:current_user)
    cu ||= master.current_user if master
    if cu
      data[:current_user_instance] ||= cu
      data[:current_user] ||= cu.attributes
      data[:current_user_email] ||= cu.email
      data[:current_user_preference] ||= cu.user_preference.attributes
      data[:current_user_contact_info] = cu.contact_info&.attributes || Users::ContactInfo.new.attributes
    end

    data
  end

  # Associations that are allowable when getting model associations to resolve tags
  def self.allowable_associations
    (Master.get_all_associations +
      Master.get_all_associations(:has_one) -
      %w[not_trackers not_tracker_histories trackers_item_flags]).uniq
  end

  #
  # Get requested master association into its own data item
  # such as data[:ipa_appointments]. The attributes of the first record from the
  # association are added to this entry, and returned.
  #
  # Allow data item to retrieve data from based on a chain of one or more associations / references
  # Associations / references are chained with dots. Only the final item's attributes are returned
  #
  #
  # @param [Master] master the current master instance
  # @param [String|Symbol] name the association to get
  # @param [Hash] data passed from {substitute}, which will gain an entry [:<name>]
  # @return [Hash] just this particular association result (the first records attributes)
  def self.get_assoc(master, ref_parts, data)
    return nil unless master

    an = ref_parts.join('.').to_sym

    begin
      res_data = data
      item_reference = false
      ref_parts.each do |name|
        # Get the associated item, based on the current part of the substitution name
        res_item = get_associated_item(master, name, res_data, item_reference: item_reference)
        res_data = nil
        break unless res_item

        res_data = setup_data res_item
        item_reference = true
      end

      return unless res_data
    rescue StandardError => e
      Rails.logger.info "Get associations for #{an} failed: #{e}"
    end

    res_data
  end

  #
  # Get requested master association into its own data item
  # such as data[:ipa_appointments].
  #
  # Special names, which are not actual associations but work like them are:
  # - ids: alternative id / value pairs
  # - parent_item:
  # - referring_record: the record referring to this item (such as an activity log referring to a dynamic model)
  # - latest_reference: the most recent reference from the record
  #
  # @param [Master] master the current master instance
  # @param [String|Symbol] name the association to get
  # @param [Hash | ActiveRecord::Model] data: object or data passed
  #    from {substitute}, from which the association or reference should be found
  # @param [Boolean] item_reference True if getting association / reference from an item rather than the master
  # @return [ActiveRecord::Model] the first item from an association or reference
  #
  def self.get_associated_item(master, name, data, item_reference: false)
    name = name.to_sym
    an = name.to_s

    return nil unless master

    item = data[:original_item] || data

    if an == 'ids'
      master.alternative_ids
    elsif data.is_a?(Hash) && data.keys.include?(name)
      data[name]
    elsif an == 'parent_item' && item.respond_to?(:container)
      item.container&.parent_item
    elsif an == 'current_user' && item.respond_to?(:current_user)
      item.current_user
    elsif an == 'referring_record' && item.respond_to?(:referring_record)
      item.referring_record
    elsif an == 'top_referring_record' && item.respond_to?(:top_referring_record)
      item.top_referring_record
    elsif an == 'latest_reference' && item.respond_to?(:latest_reference)
      item.latest_reference
    elsif item_reference
      # Match model reference by underscored to record type, or if not matched by the resource name
      # The latter allows activity logs to be matched on their extra log type too.
      # Note - beware to ensure the activity log type is singular before the extra log type
      #   activity_log__player_contact__step_1 NOT activity_log__player_contact**s**__step_1
      imr = item.model_references
      imr.select { |mr| mr.to_record_type_us == an.singularize }.first&.to_record ||
        imr.select { |mr| mr.to_record.resource_name.to_s == an }.first&.to_record
    elsif an.in? allowable_associations
      objs = master.send(an)
      if objs.respond_to? :first
        objs.first
      else
        objs
      end
    end
  end

  #
  # Handle the substitution result for [[shortlink url]] functional directive
  #
  # @param [Hash] sub_data generated in {substitute}
  # @param [String] tag_args the url to process
  # @return [String] resulting text for substitution
  #
  def self.handle_shortlink(sub_data, tag_args)
    sl = DynamicModel::ZeusShortLink.new

    raise FphsException, "No master set for create_link: #{sub_data}" unless sub_data[:master]

    res = sl.create_link(tag_args, master: sub_data[:master], batch_user: true, for_item: sub_data[:alt_item] || sub_data[:original_item])
    res[:short_link_instance]&.short_url
  end
end
