class Admin::MessageTemplate < ActiveRecord::Base

  self.table_name = 'message_templates'
  include AdminHandler
  include Formatter::Formatters

  validates :message_type, presence: true
  validates :template_type, presence: true

  scope :content_templates, ->{ where template_type: 'content' }
  scope :layout_templates, ->{ where template_type: 'layout' }
  scope :dialog_templates, ->{ where message_type: 'dialog' }

  def self.named name, type: nil
    res = where(name: name)
    res = res.where(message_type: type) if type
    res.first
  end

  def self.message_types
    [:email, :dialog, :sms]
  end

  def self.template_types
    [:layout, :content]
  end

  def layout_template?
    template_type == 'layout'
  end

  def content_template?
    template_type == 'content'
  end

  def substitute all_content, data: {}, tag_subs: nil, ignore_missing: false
    self.class.substitute all_content, data: data, tag_subs: tag_subs, ignore_missing: ignore_missing
  end


  # Perform subsititions on the the text, using either a Hash of data or an object item.
  # Provide a tag substitution to be used to enclose the substituted items
  # Substitution text examples:
  # {{select_who}} {{player_info.first_name}} {{user.email}}
  # @param all_content [String] the text containing possible {{something.else}} to be substituted
  # @param data [Hash | UserBase] represent the substitution data with a Hash or a an object instance
  # @param tag_subs [String] for example 'span class="someclass"'
  def self.substitute all_content, data: {}, tag_subs:, ignore_missing: false

    data = setup_data(data)

    tags = all_content.scan(/{{[0-9a-zA-Z_\.\:]+}}/)
    tags.each do |tag_container|
      tag = tag_container[2..-3]
      missing = false

      tagpair = tag.split('.', 2)

      d = data
      if tagpair.length == 2
        get_assoc(data[:master], tagpair.first, data)
        d = get_tag_value data, tagpair.first
        tag = tagpair.last
      end

      tag_name = tag.split('::').first

      unless d && d.is_a?(Hash) && (d.key?(tag_name) || d.key?(tag_name.to_sym))
        if ignore_missing
          d = {}
          missing = true
        else
          raise FphsException.new "Data (#{d.class.name}) does not contain the tag #{tag_name} or :#{tag_name}\n#{d ? d : 'data is empty'}"
        end
      end

      unless missing
        tag_value = get_tag_value d, tag
      else
        if ignore_missing == :show_tag
          tag_value = "{{#{tag}}}"
        else
          tag_value = ''
        end
      end
      if tag_subs
        tag_subs_type = tag_subs.split(' ').first
        tag_value = "<#{tag_subs}>#{tag_value}</#{tag_subs_type}>"
      else
        tag_value = tag_value.to_s
      end
      all_content.gsub!(tag_container, tag_value)
    end
    raise FphsException.new "Not all the tags were replaced. This suggests there was an error in the markup." if ignore_missing != :show_tag && all_content.scan(/{{.*}}/).length > 0

    tags = all_content.scan(/\[\[[^\]]+\]\]/)
    tags.each do |tag_container|
      tag = tag_container[2..-3]

      tag_parts = tag.split(' ', 2)
      tag_action = tag_parts.first

      if tag_action == 'shortlink'
        sl = DynamicModel::ZeusShortLink.new

        puts data[:master].inspect
        raise FphsException.new "No master set for create_link: #{data}" unless data[:master]
        res = sl.create_link(tag_parts[1], master: data[:master], batch_user: true, for_item: data[:alt_item] || data[:original_item])
        tag_value = res[:short_link_instance]&.short_url
      else
        raise FphsException.new "Bad message template tag action [[#{tag_action}]] specified"
      end

      all_content.gsub!(tag_container, tag_value) if tag_value

    end

    all_content
  end

  def generate content_template_name: nil, content_template_text: nil, data: {}, ignore_missing: false

    raise FphsException.new "Must use a layout template to generate from" unless layout_template?
    # raise FphsException.new "Must use a hash for data" unless !data || data.is_a?(Hash)

    if content_template_name
      content_template = Admin::MessageTemplate.active.content_templates.where(name: content_template_name).first
      raise FphsException.new "No content template found with name: #{content_template_name}" unless content_template
      content_template_text = content_template.template
    elsif !content_template_text
      raise FphsException.new "Either a content_template_name or content_template_text must be specified"
    end

    text = content_template_text.dup

    all_content = self.template.sub('{{main_content}}', text)

    substitute all_content, data: data, ignore_missing: ignore_missing

    return all_content
  end


  private
    def self.get_tag_value data, tag_and_operator

      tagp = tag_and_operator.split('::')
      tag = tagp.first
      res = data[tag] || data[tag.to_sym] || ''

      res = formatter_do(res.class, res, current_user: data[:current_user_instance])

      return if res.nil?

      # Automatically titleize names
      tagp << 'titleize'  if tagp.length == 1 &&  (tag == 'name' || tag.end_with?('_name'))
      tagp[1..-1].each do |op|

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
        elsif op == 'markup'
          res = Kramdown::Document.new(res).to_html.html_safe
        elsif op.to_i != 0
          res = res[0..op.to_i]
        end
      end

      res
    end

    def self.setup_data item, alt_item=nil

      if item.is_a? Hash
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
      if item.respond_to?(:item) && item.item.respond_to?(:attributes)
        data[:item] = item.item.attributes
      end

      if item.respond_to?(:user) && item.user
        cu = item.user
        data[:item_user] = item.user.attributes
        data[:current_user] = item.user.attributes
        data[:user_email] = item.user.email
        data[:user_preference] = item.user.user_preference.attributes

        if item.user.contact_info
          data[:user_contact_info] = item.user.contact_info.attributes
        else
          data[:user_contact_info] = Users::ContactInfo.new.attributes
        end
      end

      if item.respond_to?(:current_user) && item.current_user
        cu = item.current_user
        data[:current_user] = item.current_user.attributes
        data[:user_email] ||= item.current_user.email
        data[:user_preference] ||= item.current_user.user_preference.attributes

      end

      if item.respond_to?(:master)
        master = item.master
      elsif item.is_a? Master
        master = item
      end


      if master

        data[:master] = master
        data[:master_id] = master.id
        cu = master.current_user
        data[:current_user] = cu.attributes if cu
        data[:current_user_instance] = cu
        # Alternative ids are evaluated as needed
        # Associations are evaluated as needed in the data substitution, to avoid slowing everything down

      end

      if cu && cu.respond_to?(:contact_info) && cu.contact_info
        data[:current_user_contact_info] = cu.contact_info.attributes
      else
        data[:current_user_contact_info] = Users::ContactInfo.new.attributes
      end


      data
    end

    def self.allowable_associations
      Master.get_all_associations + Master.get_all_associations(:has_one) - ['not_trackers', 'not_tracker_histories', 'trackers_item_flags']
    end

    # Get requested master association into its own data item
    # such as data[:ipa_appointments]
    def self.get_assoc master, name, data
      an = name.to_s
      return nil unless master

      if an == 'ids'
        return data[:ids] = master.alternative_ids
      elsif an == 'referring_record'
        return data[:referring_record] = data[:original_item].respond_to?(:referring_record) && data[:original_item].referring_record&.attributes
      end


      return nil unless an.in? allowable_associations

      begin
        assoc = master.send(an)
        if assoc.respond_to? :attributes
          data[an.to_sym] ||= assoc.attributes
        elsif assoc.respond_to?(:first) && assoc.first.respond_to?(:attributes)
          data[an.to_sym] ||= assoc.first.attributes
        else
          raise "Association first item does not respond to attributes: #{an}"
        end

        data[an.to_sym][:current_user] = data[:current_user] if data[an.to_sym]
      rescue => e
        Rails.logger.info "Get associations for #{an} failed: #{e}"
      end

      data[an.to_sym]

    end

end
