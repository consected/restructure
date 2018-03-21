class MessageTemplate < ActiveRecord::Base

  include AdminHandler

  validates :message_type, presence: true
  validates :template_type, presence: true

  scope :content_templates, ->{ where template_type: 'content' }
  scope :layout_templates, ->{ where template_type: 'layout' }

  def self.named name
    where(name: name).first
  end

  def self.message_types
    [:email]
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

  def generate content_template_name: nil, data: {}

    raise FphsException.new "Must use a layout template to generate from" unless layout_template?
    raise FphsException.new "Must use a hash for data" unless data.is_a? Hash

    content_template = MessageTemplate.active.content_templates.where(name: content_template_name).first
    raise FphsException.new "No content template found with name: #{content_template_name}" unless content_template

    all_content = self.template.sub('{{main_content}}', content_template.template)

    tags = all_content.scan(/{{[0-9a-zA-z_\.]+}}/)

    tags.each do |tag_container|
      tag = tag_container[2..-3]

      raise FphsException.new "Data does not contain the tag #{tag} or :#{tag}" unless data.key?(tag) || data.key?(tag.to_sym)

      tag_value = get_tag_value data, tag
      all_content.gsub!(tag_container, tag_value.to_s)
    end

    raise FphsException.new "Not all the tags were replaced. This suggests there was an error in the markup." if all_content.scan(/{{.*}}/).length > 0

    return all_content
  end


  private
    def get_tag_value data, tag
      data[tag] || data[tag.to_sym]
    end

end
