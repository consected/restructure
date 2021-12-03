# frozen_string_literal: true

module Formatter
  class Substitution
    HtmlRegEx = /<(p ?.*|br ?.*|div ?.*|ul ?.*|hr ?.*)>/.freeze

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
    # [[shortlink https://some-thing.web/join-us/?test_id={{ids.msid}}]]
    #
    # @param all_content [String] the text containing possible {{something.else}} to be substituted
    # @param in_data [Hash | UserBase] represent the substitution data with a Hash or a an object instance
    # @param tag_subs [String] for example 'span class="someclass"'
    # @return [String] resulting text after substitution
    def self.substitute(all_content, data: {}, tag_subs: nil, ignore_missing: false)
      return unless all_content

      all_content = all_content.dup
      tags = all_content.scan(/{{[0-9a-zA-Z_.:]+}}/).uniq

      # Only setup data if there are tags
      sub_data = setup_data(data) unless tags.empty?
      # Replace each tag {{tag}}
      tags.each do |tag_container|
        tag = tag_container[2..-3]
        tag_value = value_for_tag(tag, sub_data, tag_subs, ignore_missing)

        # Finally, substitute the results into the original text
        all_content.gsub!(tag_container, tag_value)
      end

      # Unless we have requested to show missing tags, check for {{tag}} left in the text,
      # indicating something was not replaced
      if ignore_missing != :show_tag && all_content.scan(/{{.*}}/).present?
        raise FphsException, 'Not all the tags were replaced. This suggests there was an error in the markup.'
      end

      tags = all_content.scan(/\[\[[^\]]+\]\]/).uniq

      # Setup the data if it wasn't previously setup and there are tags to replace
      sub_data ||= setup_data(data) unless tags.empty?

      # Replace each tag [[tag]], representing functional directives, such as shortlink production
      tags.each do |tag_container|
        tag = tag_container[2..-3]
        tag_value = functional_directive(tag, sub_data)

        # Make the replacement
        all_content.gsub!(tag_container, tag_value) if tag_value
      end

      # Return the resulting text
      all_content
    end

    def self.value_for_tag(tag, sub_data, tag_subs, ignore_missing)
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
      this_ignore_missing = :show_blank if first_format_directive == 'ignore_missing'

      unless d.is_a?(Hash) && (d&.key?(tag_name.to_s) || d&.key?(tag_name.to_sym)) ||
             tag.start_with?('embedded_report_') || tag.start_with?('add_item_button_')
        unless ignore_missing || this_ignore_missing
          raise FphsException,
                "Data (#{d.class.name}) does not contain the tag '#{tag_name}'" \
                 "or :#{tag_name} for #{tagpair}\n#{d || 'data is empty'}"
        end

        d = {}
        missing = true
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

      tag_value
    end

    def self.functional_directive(tag, sub_data)
      tag_parts = tag.split(' ', 2)
      tag_action = tag_parts.first

      unless tag_action == 'shortlink'
        raise FphsException,
              "Bad message template tag action [[#{tag_action}]] specified"
      end

      handle_shortlink sub_data, tag_parts[1]
    end

    # If the text does not contain any HTML tags, assume it is markdown and format it as HTML
    def self.text_to_html(text)
      return text unless text.is_a? String

      has_html = !text.scan(HtmlRegEx).empty?
      text = Kramdown::Document.new(text, input: 'GFM', hard_wrap: false).to_html.html_safe unless has_html

      text
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
        data = item.dup.symbolize_keys
        master = item[:master]
        master = Master.find(item[:master_id]) if item[:master_id] && !master
      elsif item
        data = item.attributes.dup
        data[:original_item] = item
        data[:alt_item] = alt_item
        data['data'] ||= item.data if item.respond_to? :data

        if item.respond_to?(:master)
          master = item.master
        elsif item.is_a? Master
          master = item
        end
      else
        data = {}
      end

      # Common constants tags
      data[:base_url] = Settings::BaseUrl
      data[:admin_email] = Settings::AdminEmail
      data[:environment_name] = Settings::EnvironmentName
      data[:password_age_limit] = Settings::PasswordAgeLimit
      data[:password_reminder_days] = Settings::PasswordReminderDays
      data[:password_max_attempts] = Settings::PasswordMaxAttempts
      data[:mfa_disabled] = Settings::TwoFactorAuthDisabled
      data[:login_issues_url] = Settings::LoginIssuesUrl

      # if the referenced item has its own referenced item (much like an activity log might), then get it
      data[:item] = item.item.attributes.dup if item.respond_to?(:item) && item.item.respond_to?(:attributes)

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

      iu = item.user if item.respond_to?(:user) && item.respond_to?(:user_id)
      if iu
        data[:item_user] = iu.attributes.dup
        data[:user_email] = iu.email
        data[:user_preference] = iu.user_preference.attributes.dup
        data[:user_contact_info] = iu.contact_info&.attributes&.dup || Users::ContactInfo.new.attributes

      end

      cu = item.current_user if item.respond_to?(:current_user)
      cu ||= master.current_user if master
      cu ||= item if item.is_a? User
      if cu
        data[:current_user_instance] ||= cu
        data[:current_user] ||= cu.attributes.dup
        data[:current_user_email] ||= cu.email
        data[:user_email] ||= cu.email
        data[:current_user_preference] ||= cu.user_preference.attributes.dup
        data[:current_user_contact_info] = cu.contact_info&.attributes&.dup || Users::ContactInfo.new.attributes
        data[:current_user_app_type_id] = cu.app_type_id
        data[:current_user_app_type_name] = cu.app_type&.name
        data[:current_user_app_type_label] = cu.app_type&.label
      end

      data
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

      current_user = data[:current_user_instance]

      return run_embedded_report tag, data if tag.start_with? 'embedded_report_'
      return add_item_button tag, data if tag.start_with? 'add_item_button_'

      orig_val = data[tag] || data[tag.to_sym]
      res = orig_val || ''

      res = Formatter::Formatters.formatter_do(res.class, res, current_user: current_user)

      return if res.nil? && tagp[1] != 'ignore_missing'

      # Automatically titleize names
      tagp << 'titleize' if tagp.length == 1 && (tag == 'name' || tag.end_with?('_name'))
      tagp[1..].each do |op|
        # NOTE: if additional formatters are added here, they also need matching javascript
        # in _fpa_form_utils.format_subtitution
        res = TagFormatter.format_with(op, res, orig_val)
      end

      res
    end

    #
    # Find the source item to call an embedded report or add an item with
    def self.source_for(data)
      if data[:original_item].respond_to?(:referring_record) && data[:original_item].referring_record
        list_item = data[:original_item].referring_record
        list_id = list_item.id
        list_master_id = list_item.master_id if list_item.respond_to?(:master_id)
      else
        list_item = data[:original_item]
        list_id = list_item[:id]
        list_master_id = list_item[:master_id]
      end
      [list_item, list_id, list_master_id]
    end

    def self.run_embedded_report(tag, data)
      report_name = tag.sub('embedded_report_', '')
      list_item, list_id, = source_for(data)
      list_type = list_item.class.name

      Reports::Template.embedded_report report_name, list_id, list_type
    end

    def self.add_item_button(tag, _data)
      model_name = tag.sub('add_item_button_', '')

      if model_name.start_with? 'to_master_'
        _, _, add_to_master = source_for(data)
        model_name = model_name.sub('to_master_', '')
      end

      Formatter::AddItemButton.markup model_name, add_to_master
    end

    # Associations that are allowable when getting model associations to resolve tags
    def self.allowable_master_associations
      (Master.get_all_associations +
        Master.get_all_associations(:has_one) -
        %w[not_trackers not_tracker_histories trackers_item_flags]).uniq
    end

    # Associations that are allowable when getting model associations to resolve tags
    def self.allowable_associations(from_item)
      return [] unless from_item.respond_to? :reflect_on_all_associations

      (from_item.reflect_on_all_associations.map { |a| a.name.to_s } -
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
      elsif an == 'first' && item.respond_to?(:first)
        item.first
      elsif an == 'constants'
        # Options constants
        item.versioned_definition.options_constants&.dup if item.respond_to?(:versioned_definition)
      elsif an == 'app_protocols' && master.current_user
        Classification::Protocol
          .enabled
          .where(
            app_type_id: [master.current_user.app_type_id, nil]
          )
          .order(position: :asc)
          .first
      elsif an.in?(allowable_associations(item.class))
        objs = item.send(an)
        if objs.respond_to? :first
          objs.first
        else
          objs
        end
      elsif an.in? allowable_master_associations
        objs = master.send(an)
        if objs.respond_to? :first
          objs.first
        else
          objs
        end
      elsif item_reference
        # Match model reference by underscored to record type, or if not matched by the resource name
        # The latter allows activity logs to be matched on their extra log type too.
        # Note - beware to ensure the activity log type is singular before the extra log type
        #   activity_log__player_contact__step_1 NOT activity_log__player_contact**s**__step_1
        imr = item.model_references
        imr.select { |mr| mr.to_record_type_us == an.singularize }
           .first&.to_record ||
          imr.select { |mr| mr.to_record.resource_name.to_s == an }
             .first&.to_record
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

      res = sl.create_link(tag_args,
                           master: sub_data[:master],
                           batch_user: true,
                           for_item: sub_data[:alt_item] || sub_data[:original_item])

      res[:short_link_instance]&.short_url
    end
  end
end
