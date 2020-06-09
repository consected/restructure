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

      tagpair = tag.split('.', 2)

      d = sub_data
      if tagpair.length == 2
        # For {{tag.attr}} items, get the association (if needed), then
        # get the actual attribute value
        get_assoc(sub_data[:master], tagpair.first, sub_data)
        d = get_tag_value sub_data, tagpair.first
        # Make the current tag just the attribute name, since it may include {{attr::formatting}} to be processed
        tag = tagpair.last
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
      item = item.dup
      item.symbolize_keys!
      item[:master] = Master.find(item[:master_id]) if item[:master_id] && !item[:master]
      item[:master_id] ||= item[:master].id if item[:master] && !item[:master_id]
      return item
    end

    data = item.attributes.dup

    data[:original_item] = item
    data[:alt_item] = alt_item
    data[:base_url] = Settings::BaseUrl
    data[:admin_email] = Settings::AdminEmail
    data[:environment_name] = Settings::EnvironmentName
    data[:password_age_limit] = Settings::PasswordAgeLimit
    data[:password_reminder_days] = Settings::PasswordReminderDays

    # if the referenced item has its own referenced item (much like an activity log might), then get it
    data[:item] = item.item.attributes if item.respond_to?(:item) && item.item.respond_to?(:attributes)

    if item.respond_to?(:user) && item.user
      cu = item.user
      data[:item_user] = item.user.attributes
      data[:current_user] = item.user.attributes
      data[:user_email] = item.user.email
      data[:user_preference] = item.user.user_preference.attributes
      data[:user_contact_info] = if item.user.contact_info
                                   item.user.contact_info.attributes
                                 else
                                   Users::ContactInfo.new.attributes
      end
    end

    data[:created_by_user] = nil
    data[:created_by_user_email] = nil

    if item.respond_to?(:created_by_user)
      data[:created_by_user] = item.created_by_user
      data[:created_by_user_email] = item.created_by_user_email
    end

    if item.respond_to?(:current_user) && item.current_user
      cu = item.current_user
      data[:current_user] = item.current_user.attributes
      data[:user_email] ||= item.current_user.email
      data[:user_preference] ||= item.current_user.user_preference.attributes
      data[:current_user_email] ||= item.current_user.email
      data[:current_user_preference] ||= item.current_user.user_preference.attributes

    end

    if item.respond_to?(:master)
      master = item.master
    elsif item.is_a? Master
      master = item
    end

    data[:parent_item] = item.container&.parent_item&.attributes if item.respond_to?(:container)

    if master

      data[:master] = master
      data[:master_id] = master.id
      cu = master.current_user
      data[:current_user] = cu.attributes if cu
      data[:current_user_instance] = cu
      # Alternative ids are evaluated as needed
      # Associations are evaluated as needed in the data substitution, to avoid slowing everything down

    end

    data[:current_user_contact_info] = if cu&.respond_to?(:contact_info) && cu&.contact_info
                                         cu.contact_info.attributes
                                       else
                                         Users::ContactInfo.new.attributes
                                       end

    data
  end

  # Associations that are allowable when getting model associations to resolve tags
  def self.allowable_associations
    Master.get_all_associations + Master.get_all_associations(:has_one) - %w[not_trackers not_tracker_histories trackers_item_flags]
  end

  #
  # Get requested master association into its own data item
  # such as data[:ipa_appointments]. The attributes of the first record from the
  # association are added to this entry, and returned.
  #
  # Special names, which are not actual associations but work like them are:
  # - ids: alternative id / value pairs
  # - referring_record: the record referring to this item (such as an activity log referring to a dynamic model)
  #
  # @param [Master] master the current master instance
  # @param [String|Symbol] name the association to get
  # @param [Hash] data passed from {substitute}, which will gain an entry [:<name>]
  # @return [Hash] just this particular association result (the first records attributes)
  #
  def self.get_assoc(master, name, data)
    an = name.to_s
    return nil unless master

    if an == 'ids'
      return data[:ids] = master.alternative_ids
    elsif an == 'parent_item'
      return data[:parent_item]
    elsif an == 'referring_record'
      return data[:referring_record] = data[:original_item].respond_to?(:referring_record) &&
                                       data[:original_item].referring_record&.attributes
    elsif an == 'latest_reference'
      return data[:latest_reference] = data[:original_item].respond_to?(:model_references) &&
                                       data[:original_item].model_references(ref_order: { id: :desc })
                                                           .first
                                                           &.to_record&.attributes
    end

    return nil unless an.in? allowable_associations

    begin
      # Get the association and find the first result
      assoc = master.send(an)
      if assoc.respond_to? :attributes
        item = assoc
      elsif assoc.respond_to?(:first)
        item = assoc.first
      else
        raise "Association first item does not respond to attributes: #{an}"
      end

      # Set the attributes
      if item.respond_to?(:attributes)
        data[an.to_sym] ||= item.attributes
      else
        return nil
      end

      ditem = data[an.to_sym]
      if ditem

        # If we got a result, update it with additional information
        add_data = setup_data item
        ditem.merge!(add_data)

        # Force the current user information to match the supplied data if it hasn't been set
        ditem[:current_user] ||= data[:current_user]
        ditem[:current_user_instance] ||= data[:current_user_instance]

      end
    rescue StandardError => e
      Rails.logger.info "Get associations for #{an} failed: #{e}"
    end

    ditem
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
