# frozen_string_literal: true

module Formatter
  class Substitution
    HtmlRegEx = /<(p|br|div|ul|hr|p .+=.+|br |div .+=.+|ul .+=.+|hr .+=.+)>/
    TagnameRegExString = '[0-9a-zA-Z_.:\-]+'

    # Gets an array of 5 element arrays for each {(#if <tagname>}}true text{{else}}else text{{/if}}
    # - the full matched block
    # - tagname
    # - true text
    # - truthy if there is an {{else}}
    # - else text
    IfBlockRegEx = %r{({{#if (#{TagnameRegExString})}}(.+?)({{else if (#{TagnameRegExString})}}(.+?))?({{else}}(.+?))?{{/if}})}m

    IsOperator = '["\']===|!===|==|!==|<|>|<=|>=["\']'
    IsExpectedResult = '["\']?.+["\']?'
    StartQuote = '["\'‘]'
    EndQuote = '["\'’]'
    IsBlockRegEx = %r{({{#is ([0-9a-zA-Z_.:-]+) #{StartQuote}(===|!===|==|!==|<|>|<=|>=)#{EndQuote} (#{StartQuote}?.+?#{EndQuote}?)}}(.+?)({{else}}(.+?))?{{/is}})}m

    OverrideTags = /^(embedded_report_|add_item_button_|glyphicon_|template_block_)/

    FunctionalDirectives = %w[shortlink].freeze
    FunctionalDirectiveRegEx = /\[\[[^\]]+\]\]/

    # Set the methods from certain resources that should be accessible for substitution
    # as if they were real attributes
    ValidMethodsAsAttributes = { player_infos: %i[subject_age rank_name] }

    NoAutoTitleizeTags = %w[resource_name item_type_name default_embed_resource_name
                            definition_resource_name definition_item_type_name].freeze
    #
    # Perform substitutions on the text, using either a Hash of data or an object item.
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
    # @param ignore_missing [true|false|nil|Symbol] - one of:
    #    :show_tag - show the tag if missing
    #    true - quietly ignore the missing tag
    #    false, nil - raise exception if tag is missing
    # @return [String] resulting text after substitution
    def self.substitute(all_content, data: {}, tag_subs: nil, ignore_missing: false)
      return unless all_content

      all_content = all_content.dup

      # Do an initial check for functional directives, just to see if they exist
      # This is to avoid the situation where a tag results in text like [[some value]]
      # which would then be treated as a functional directive.
      has_functional_directives = all_content.scan(FunctionalDirectiveRegEx).present?

      # Only setup data if there are double curly brackets
      sub_data = setup_data(data) if all_content.index('{{')

      # Replace each if block {{#if ...}}...(optional {{else}}...){{/if}}
      if_blocks = all_content.scan(IfBlockRegEx)
      if_blocks.each do |if_block|
        block_container = if_block[0]
        tag = if_block[1]
        tag_value = value_for_tag(tag, sub_data, tag_subs: nil, ignore_missing: true)
        else_if_block = if_block[3]
        else_if_tag = if_block[4]

        # Handle {{if}}
        sub_text = if_block[2] || '' if tag_value.present?

        if !sub_text && else_if_block
          elsif_tag_value = value_for_tag(else_if_tag, sub_data, tag_subs: nil, ignore_missing: true)
          sub_text = if_block[5] || '' if elsif_tag_value.present?
        end

        # Handle {{else}}
        sub_text ||= if_block[7] || ''

        all_content.sub!(block_container, sub_text)
      end

      # Replace each if block {{#is ...}}...(optional {{else}}...){{/is}}
      is_blocks = all_content.scan(IsBlockRegEx)
      is_blocks.each do |is_block|
        block_container = is_block[0]
        tag = is_block[1]
        tag_value = value_for_tag(tag, sub_data, tag_subs: nil, ignore_missing: true)
        op = is_block[2]
        exp = is_block[3]

        exp_parts = exp.match(/(#{StartQuote})(.+)(#{EndQuote})/)
        exp = if exp_parts[1] && exp_parts[3]
                exp_parts[2]
              elsif exp_parts[2].to_i.to_s == exp_parts[2]
                exp_parts[2].to_i
              else
                value_for_tag(exp_parts[2], sub_data, tag_subs: nil, ignore_missing: true)
              end

        comp = case op
               when '==='
                 tag_value == exp
               when '!=='
                 tag_value != exp
               when '=='
                 tag_value == exp
               when '!='
                 tag_value != exp
               when '>='
                 tag_value >= exp
               when '<='
                 tag_value <= exp
               when '>'
                 tag_value > exp
               when '<'
                 tag_value < exp
               end

        if comp
          all_content.sub!(block_container, is_block[4] || '')
        else
          all_content.sub!(block_container, is_block[6] || '')
        end
      end

      # Replace each tag {{tag}}
      tags = all_content.scan(/{{#{TagnameRegExString}}}/).uniq
      tags.each do |tag_container|
        tag = tag_container[2..-3]
        tag_value = value_for_tag(tag, sub_data, tag_subs:, ignore_missing:)

        # Finally, substitute the results into the original text
        all_content.gsub!(tag_container, tag_value)
      end

      # Unless we have requested to show missing tags, check for {{tag}} left in the text,
      # indicating something was not replaced
      if ignore_missing != :show_tag && ignore_missing != true && all_content.scan(/{{.*}}/).present?
        raise FphsException, 'Not all the tags were replaced. This suggests there was an error in the markup.'
      end

      if has_functional_directives
        tags = all_content.scan(FunctionalDirectiveRegEx).uniq

        # Setup the data if it wasn't previously setup and there are tags to replace
        sub_data ||= setup_data(data) unless tags.empty?

        # Replace each tag [[tag]], representing functional directives, such as shortlink production
        tags.each do |tag_container|
          tag = tag_container[2..-3]
          tag_value = functional_directive(tag, sub_data, ignore_missing:)

          # Make the replacement
          all_content.gsub!(tag_container, tag_value) if tag_value
        end
      end

      all_content&.gsub!('\{\{', '{{')&.gsub!('\}\}', '}}')

      # Return the resulting text
      all_content
    end

    #
    # Perform a plain substitution of a triple-curly tag, returning the original type,
    # without casting to a string. This allows object / hash data to be retrieved
    # For example: specifying content as '{{{db_object.inner_structure}}}'
    # for data {a:1, inner_structure: {b:2, c:3}, d: 'nothing'}
    # would return the Hash {b:2, c:3}
    # @param [String] content
    # @param [Hash] data
    # @return [Object|nil]
    def self.substitute_plain(content, data: {})
      tagnames = content.match(/{{{(.+)}}}/)
      tagname = tagnames[1]
      return unless tagname

      sub_data = Formatter::Substitution.setup_data(data)
      Formatter::Substitution.value_for_tag(tagname, sub_data, ignore_missing: true, original_type: true)
    end

    def self.value_for_tag(tag, sub_data, tag_subs: nil, ignore_missing: nil, original_type: nil)
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

      d = d.first if d.respond_to? :where
      orig_item = d
      d = d.attributes if d.respond_to? :attributes
      d[:original_item] ||= orig_item if d.is_a?(Hash)

      # Handle formatting directives, following the ::
      tag_split = tag.split('::')
      tag_name = tag_split.first
      first_format_directive = tag_split[1]
      this_ignore_missing = :show_blank if first_format_directive == 'ignore_missing'
      setup_methods_as_attributes(d)

      unless d.is_a?(Hash) && (d&.key?(tag_name.to_s) ||
              d&.key?(tag_name.to_sym)) ||
             tag.index(OverrideTags) ||
             d.is_a?(Enumerable) && (tag_name.to_s == tag_name.to_s.to_i.to_s || tag_name.in?(['first', 'last']))
        unless ignore_missing || this_ignore_missing
          raise FphsException,
                "Data (#{d.class.name}) does not contain the tag '#{tag_name}' " \
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
      elsif original_type
        # tag_value should be returned without casting
      else
        tag_value = tag_value.to_s
      end

      tag_value
    end

    def self.functional_directive(tag, sub_data, ignore_missing: nil)
      tag_parts = tag.split(' ', 2)
      tag_action = tag_parts.first

      unless ignore_missing || tag_action.in?(FunctionalDirectives)
        raise FphsException,
              "Bad message template tag action [[#{tag_action}]] specified"
      end

      handle_shortlink sub_data, tag_parts[1]
    end

    # If the text does not contain any HTML tags, assume it is markdown and format it as HTML
    def self.text_to_html(text)
      return text unless text.is_a? String

      has_html = !text.scan(HtmlRegEx).empty?
      text = Kramdown::Document.new(text, input: 'GFM', hard_wrap: false).to_html.strip.html_safe unless has_html

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
        item = item.first if item.respond_to? :where
        data = item.attributes.dup
        data[:original_item] = item
        data[:alt_item] = alt_item
        data['data'] ||= item.data if item.respond_to? :data
        data['save_trigger_results'] = item.save_trigger_results if item.respond_to? :save_trigger_results

        if item.respond_to?(:master)
          master = item.master
        elsif item.is_a? Master
          master = item
        end
        data[:class_name] = item.class.name
      else
        data = {}
      end

      setup_resource_info(data)
      setup_common_constants_tags(data)
      setup_data_for_referenced_item(data, item)
      setup_data_created_by(data, item)
      setup_data_for_master(data, master)
      setup_data_for_item_user(data, item)
      setup_data_for_current_user(data, master, item)
      setup_methods_as_attributes(data)
      data
    end

    ##### The following methods are not intended for use outside this class ######

    # if the item has its own referenced item (much like an activity log might), then get it
    def self.setup_data_for_referenced_item(data, item)
      data[:item] = item.item.attributes.dup if item.respond_to?(:item) && item.item.respond_to?(:attributes)
    end

    # setup data from created_by_user on item
    def self.setup_data_created_by(data, item)
      data[:created_by_user] = nil
      data[:created_by_user_email] = nil

      return unless item.respond_to?(:created_by_user)

      data[:created_by_user] = item.created_by_user
      data[:created_by_user_email] = item.created_by_user_email
    end

    # setup data for master
    def self.setup_data_for_master(data, master)
      return unless master

      data[:master] = master
      data[:master_id] ||= master.id

      # Check if the master responds to the underlying attribute, since there are times when a query
      # on the masters table returns a very limited set of fields
      return unless master.respond_to? :created_by_user_id

      data[:master_created_by_user] = master.master_created_by_user
      data[:master_created_by_user_email] = master.master_created_by_user&.email

      # Alternative ids are evaluated as needed
      # Associations are evaluated as needed in the data substitution, to avoid slowing everything down
    end

    # setup data for item user_id
    def self.setup_data_for_item_user(data, item)
      iu = item.user if item.respond_to?(:user) && item.respond_to?(:user_id)
      return unless iu.is_a? User

      data[:item_user] = iu.attributes.dup
      data[:user_email] = iu.email
      data[:user_preference] = iu.user_preference&.attributes&.dup
      data[:user_contact_info] = iu.contact_info&.attributes&.dup || Users::ContactInfo.new.attributes
    end

    # setup data for current user from item or master
    def self.setup_data_for_current_user(data, master, item)
      cu = item.current_user if item.respond_to?(:current_user)
      cu ||= master.current_user if master
      cu ||= item if item.is_a? User
      cu ||= data[:current_user]
      return unless cu.is_a? User

      data[:current_user_instance] ||= cu
      data[:current_user] ||= cu.attributes.dup
      data[:current_user_email] ||= cu.email
      data[:user_email] ||= cu.email
      data[:current_user_preference] ||= cu.user_preference&.attributes&.dup
      data[:current_user_contact_info] = cu.contact_info&.attributes&.dup || Users::ContactInfo.new.attributes
      data[:current_user_app_type_id] = cu.app_type_id
      data[:current_user_app_type_name] = cu.app_type&.name
      data[:current_user_app_type_label] = cu.app_type&.label
      data[:current_user_password_expires_in] = cu.expires_in

      cur = data[:current_user_roles] = {}
      cu.role_names.each do |rn|
        sym = rn.id_underscore.to_sym
        cur[sym] = rn
      end
    end

    #
    # Certain methods in resources should be accessible as attributes for substitution
    # Set these up
    def self.setup_methods_as_attributes(data)
      return unless data

      orig_obj = data[:original_item]
      rn = data[:resource_name]
      rn ||= orig_obj.resource_name if orig_obj.respond_to?(:resource_name)
      rn = rn&.to_sym
      return unless rn && ValidMethodsAsAttributes[rn]

      ValidMethodsAsAttributes[rn].each do |tag_name|
        data[tag_name] = orig_obj.send(tag_name) if orig_obj.respond_to?(tag_name)
      end
    end

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

      if data.is_a?(Enumerable) && (tag.to_i.to_s == tag || tag.in?(['first', 'last']))
        tag = case tag
              when 'first' then '0'
              when 'last' then '-1'
              else tag
              end
        orig_val = data[tag.to_i]
      else
        current_user = data[:current_user_instance] || data[:current_user]

        return template_block tag, data if tag.start_with? 'template_block_'
        return glyphicon tag, data if tag.start_with? 'glyphicon_'
        return run_embedded_report tag, data if tag.start_with? 'embedded_report_'
        return add_item_button tag, data if tag.start_with? 'add_item_button_'

        orig_val = data[tag] || data[tag.to_sym]
      end

      res = orig_val || ''

      res = Formatter::Formatters.formatter_do(res.class, res, current_user:)

      return if res.nil? && tagp[1] != 'ignore_missing'

      # Automatically titleize names (only if the returned value is a string)
      if res.is_a?(String) &&
         tagp.length == 1 &&
         (tag == 'name' || tag.end_with?('_name')) &&
         !tag.in?(NoAutoTitleizeTags)
        tagp << 'titleize'
      end
      tagp[1..].each do |op|
        res = TagFormatter.format_with(op, res, orig_val, current_user, tag, data)
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

    def self.template_block(tag, data)
      block_name = tag.sub('template_block_', '').gsub('_', ' ')
      ApplicationController.helpers.template_block(block_name, data:)
    end

    def self.glyphicon(tag, _data)
      icon = tag.sub('glyphicon_', '').gsub('_', '-')

      "<span class=\"glyphicon glyphicon-#{icon}\"></span>".html_safe
    end

    def self.run_embedded_report(tag, data)
      report_name = tag.sub('embedded_report_', '')
      list_item, list_id, list_master_id = source_for(data)
      list_type = list_item.class.name

      Reports::Template.embedded_report report_name, list_id, list_type, list_master_id
    end

    def self.add_item_button(tag, data)
      model_name = tag.sub('add_item_button_', '')

      if model_name.start_with? 'to_master_'
        _, _, add_to_master = source_for(data)
        model_name = model_name.sub('to_master_', '')
      elsif model_name.start_with? 'to_temporary_master_'
        add_to_master = -1
        model_name = model_name.sub('to_temporary_master_', '')
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
    # @param [String|Symbol] ref_parts - array of parts specifying the association to get
    # @param [Hash] data passed from {substitute}, which will gain an entry [:<name>]
    # @return [Hash] just this particular association result (the first records attributes)
    def self.get_assoc(master, ref_parts, data)
      begin
        res_data = data
        item_reference = false
        ref_parts.each do |name|
          # Get the associated item, based on the current part of the substitution name
          res_data = get_associated_item(master, name, res_data, item_reference:)

          break unless res_data.present?

          item_reference = true
        end

        res_data = setup_data res_data if res_data

        return unless res_data
      rescue StandardError => e
        an = ref_parts.join('.').to_sym
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
    # - embedded_item: the direct embedded item
    #
    # @param [Master] master the current master instance
    # @param [String|Symbol] name the association to get
    # @param [Hash | ActiveRecord::Model] data: object or data passed
    #    from {substitute}, from which the association or reference should be found
    # @param [Boolean] item_reference True if getting association / reference from an item rather than the master
    # @return [ActiveRecord::Model] the first item from an association or reference
    #
    def self.get_associated_item(master, name, data, item_reference: false)
      data, is_index = init_associated_data(name, data)
      data = setup_data data if data
      return unless data

      item = data[:original_item] if data.is_a? Hash
      item ||= data
      return item if is_index

      res = associated_reference(name, data, item, item_reference)
      # If we found a value already, return it.
      return res unless res == :no_value

      associated_master_and_configs(master, name)
    end

    def self.associated_reference(name, data, item, item_reference)
      symname = name.to_sym
      name = name.to_s

      if data.is_a?(Hash) && data.keys.include?(symname)
        data[symname]
      elsif name == 'parent_item' && item.respond_to?(:container)
        item.container&.parent_item
      elsif name == 'current_user' && item.respond_to?(:current_user)
        item.current_user
      elsif name == 'referring_record' && item.respond_to?(:referring_record)
        item.referring_record
      elsif name == 'top_referring_record' && item.respond_to?(:top_referring_record)
        item.top_referring_record
      elsif name == 'latest_reference' && item.respond_to?(:latest_reference)
        item.latest_reference
      elsif name == 'embedded_item' && item.respond_to?(:embedded_item)
        item.embedded_item
      elsif name == 'constants'
        # Options constants
        item.versioned_definition.options_constants&.dup if item.respond_to?(:versioned_definition)
      elsif name.in?(allowable_associations(item.class))
        item.send(name)
      elsif item_reference
        # Match model reference by underscored to record type, or if not matched by the resource name
        # The latter allows activity logs to be matched on their extra log type too.
        # Note - beware to ensure the activity log type is singular before the extra log type
        #   activity_log__player_contact__step_1 NOT activity_log__player_contact**s**__step_1
        imr = item.model_references
        imr.select { |mr| mr.to_record_type_us == name.singularize }
           .first&.to_record ||
          imr.select { |mr| mr.to_record.resource_name.to_s == name }
             .first&.to_record
      else
        :no_value
      end
    end

    def self.init_associated_data(name, data)
      name = name.to_s
      anumber = name.to_i
      is_index = false
      data = if name == 'first' && data.respond_to?(:first)
               is_index = true
               data.first
             elsif name == 'last' && data.respond_to?(:last)
               is_index = true
               data.last
             elsif name == 'json_parse' && data.is_a?(String)
               is_index = true
               JSON.parse(data) if data.present?
             elsif anumber.to_s == name && data.is_a?(Enumerable)
               is_index = true
               data[anumber]
             elsif data.respond_to? :where
               data.first
             else
               data
             end

      [data, is_index]
    end

    # These tests rely on this item having a master set.
    # If it isn't set, just return nil. If it is set, continue through the master related tests.
    def self.associated_master_and_configs(master, name)
      name = name.to_s
      if !master
        nil
      elsif name == 'ids'
        master.alternative_ids
      elsif name == 'app_protocols' && master.current_user
        Classification::Protocol
          .enabled
          .where(
            app_type_id: [master.current_user.app_type_id, nil]
          )
          .order(position: :asc)
          .first
      elsif name == 'app_configurations' && master.current_user
        Admin::AppConfiguration.all_for(master.current_user)
      elsif name.in? allowable_master_associations
        master.send(name)
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

    #
    # Common constants tags
    # @param [Hash] data - hash to set up with common constants
    def self.setup_common_constants_tags(data)
      data[:base_url] = Settings::BaseUrl
      data[:admin_email] = Settings::AdminEmail
      data[:environment_name] = Settings::EnvironmentName
      data[:password_age_limit] = Settings::PasswordAgeLimit
      data[:password_reminder_days] = Settings::PasswordReminderDays
      data[:password_max_attempts] = Settings::PasswordMaxAttempts
      data[:password_min_entropy] = Settings::PasswordConfig[:min_entropy]
      data[:password_min_length] = Settings::PasswordConfig[:min_length]
      data[:password_regex_requirements] = Settings::PasswordConfig[:regex_requirements]
      data[:password_unlock_time_mins] = Settings::PasswordUnlockTimeMins
      data[:user_session_timeout] = (Settings::UserTimeout.to_i / 60)
      data[:mfa_disabled] = User.two_factor_auth_disabled
      data[:login_issues_url] = Settings::LoginIssuesUrl
      data[:allow_users_to_register] = Settings::AllowUsersToRegister ? true : nil
      data[:did_not_receive_confirmation_instructions_url] = Settings::DidntReceiveConfirmationInstructionsUrl
      data[:notifications_from_email] = Settings::NotificationsFromEmail
      data[:two_factor_auth_issuer] = Settings::TwoFactorAuthIssuer
      data[:allow_admins_to_manage_admins] = Settings::AllowAdminsToManageAdmins
      data[:invitation_code] = Settings::InvitationCode
      data[:default_logo] = Settings::DefaultLogo
    end

    def self.setup_resource_info(data)
      item = data[:original_item]
      data[:resource_name] = item.resource_name if item.respond_to?(:resource_name)
      data[:table_name] = item.class.table_name if item.class.respond_to?(:table_name)
      data[:item_type_name] = item.full_item_type_name if item.respond_to?(:full_item_type_name)

      idef = item.class.definition if item.class.respond_to? :definition
      return unless idef.is_a?(ActivityLog)

      data[:definition_resource_name] = idef.resource_name
      data[:definition_item_type_name] = idef.item_type_name

      if idef.respond_to?(:default_embed_resource_name)
        data[:default_embed_resource_name] = idef.default_embed_resource_name(item.extra_log_type)
      end

      nil
    end
  end
end
