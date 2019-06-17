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
    tags = all_content.scan(/{{[0-9a-zA-Z_\.\:]+}}/)

    data = setup_data(data) unless data.is_a? Hash

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
      op = tagp[1]
      res = data[tag] || data[tag.to_sym] || ''

      res = formatter_do(res.class, res, current_user: data[:current_user])

      return if res.nil?

      # Automatically titleize names
      op ||= 'titleize'  if tag == 'name' || tag.end_with?('_name')

      if op == 'capitalize'
        res = res.capitalize
      elsif op == 'titleize'
        res = res.titleize
      elsif op == 'uppercase'
        res = res.upcase
      elsif op == 'lowercase'
        res = res.downcase
      end

      res
    end

    def self.setup_data item
      data = item.attributes.dup

      data[:base_url] = Settings::BaseUrl
      data[:admin_email] = Settings::AdminEmail
      data[:environment_name] = Settings::EnvironmentName
      data[:password_age_limit] = Settings::PasswordAgeLimit
      data[:password_reminder_days] = Settings::PasswordReminderDays

      # if the referenced item has its own referenced item (much like an activity log might), then get it
      if item.respond_to?(:item) && item.item.respond_to?(:attributes)
        data[:item] = item.item
      end

      if item.respond_to?(:user) && item.user
        data[:user_email] = item.user.email
        data[:user_preference] = item.user.user_preference
      end

      if item.respond_to?(:current_user) && item.current_user
        data[:user_email] ||= item.current_user.email
        data[:user_preference] ||= item.current_user.user_preference
      end

      if item.respond_to?(:master)
        master = item.master
      elsif item.is_a? Master
        master = item
      end


      if master

        data[:master] = master
        data[:master_id] = master.id
        data[:current_user] = master.current_user
        # Alternative ids are evaluated as needed
        # Associations are evaluated as needed in the data substitution, to avoid slowing everything down

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
      end


      return nil unless an.in? allowable_associations

      begin
        assoc = master.send(an)
        if assoc.respond_to? :attributes
          data[an.to_sym] ||= assoc.attributes
        elsif assoc.respond_to? :first
          data[an.to_sym] ||= assoc.first.attributes
        end

        data[an.to_sym][:current_user] = data[:current_user] if data[an.to_sym]
      rescue => e
        Rails.logger.info "Get associations for #{an} failed: #{e}"
      end

      data[an.to_sym]

    end

end
