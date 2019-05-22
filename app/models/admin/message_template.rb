class Admin::MessageTemplate < ActiveRecord::Base

  self.table_name = 'message_templates'
  include AdminHandler

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

  def substitute all_content, data: {}, tag_subs: nil
    self.class.substitute all_content, data: data, tag_subs: tag_subs
  end


  # Perform subsititions on the the text, using either a Hash of data or an object item.
  # Provide a tag substitution to be used to enclose the substituted items
  # Substitution text examples:
  # {{select_who}} {{player_info.first_name}} {{user.email}}
  # @param all_content [String] the text containing possible {{something.else}} to be substituted
  # @param data [Hash | UserBase] represent the substitution data with a Hash or a an object instance
  # @param tag_subs [String] for example 'span class="someclass"'
  def self.substitute all_content, data: {}, tag_subs:, ignore_missing: false
    tags = all_content.scan(/{{[0-9a-zA-Z_\.]+}}/)

    data = setup_data(data) unless data.is_a? Hash

    tags.each do |tag_container|
      tag = tag_container[2..-3]

      tagpair = tag.split('.', 2)

      d = data
      if tagpair.length == 2
        d = get_tag_value data, tagpair.first
        tag = tagpair.last
      end

      unless d && d.is_a?(Hash) && (d.key?(tag) || d.key?(tag.to_sym))
        if ignore_missing
          d = {}
        else
          raise FphsException.new "Data does not contain the tag #{tag} or :#{tag}\n#{d ? d : 'data is empty'}"
        end
      end

      tag_value = get_tag_value d, tag
      if tag_subs
        tag_subs_type = tag_subs.split(' ').first
        tag_value = "<#{tag_subs}>#{tag_value}</#{tag_subs_type}>"
      else
        tag_value = tag_value.to_s
      end
      all_content.gsub!(tag_container, tag_value)
    end
    raise FphsException.new "Not all the tags were replaced. This suggests there was an error in the markup." if all_content.scan(/{{.*}}/).length > 0
    all_content
  end

  def generate content_template_name: nil, data: {}

    raise FphsException.new "Must use a layout template to generate from" unless layout_template?
    raise FphsException.new "Must use a hash for data" unless !data || data.is_a?(Hash)

    content_template = Admin::MessageTemplate.active.content_templates.where(name: content_template_name).first
    raise FphsException.new "No content template found with name: #{content_template_name}" unless content_template

    all_content = self.template.sub('{{main_content}}', content_template.template)

    substitute all_content, data: data

    return all_content
  end


  private
    def self.get_tag_value data, tag
      res = data[tag] || data[tag.to_sym] || ''

      if res.is_a?(Date) && data[:current_user]
        df = data[:current_user].user_preference.pattern_for_date_format
        res = res.strftime(df)
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
        data[:item] = item.item.attributes
      end

      if item.respond_to?(:user) && item.user
        data[:user_email] = item.user.email
      end

      if item.respond_to?(:current_user) && item.current_user
        data[:user_email] ||= item.current_user.email
      end

      if item.respond_to?(:master)
        master = item.master
      elsif item.is_a? Master
        master = item
      end


      # Keep the singular version of player_info for compatibility with existing templates
      if master && master.respond_to?(:player_infos) && master.player_infos&.first
        data[:player_info] = master.player_infos.first.attributes
      end


      if master
        data[:current_user] = master.current_user

        data[:ids] = master.alternative_ids

        # Get all master associations into their respective items
        # such as data[:ipa_appointments]
        aa = Master.get_all_associations - ['not_trackers', 'not_tracker_histories', 'trackers_item_flags']

        aa.each do |an|
          begin
            data[an.to_sym] ||= master.send(an).first&.attributes
            data[an.to_sym][:current_user] = data[:current_user] if data[an.to_sym]
          rescue => e
            Rails.logger.info "Get associations for #{an} failed: #{e}"
          end
        end

      end



      data
    end

end
