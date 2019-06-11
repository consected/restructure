class Admin::PageLayout < ActiveRecord::Base

  self.table_name = 'page_layouts'

  include AdminHandler
  include AppTyped

  validates :app_type_id, presence: {scope: :active}
  validates :layout_name, presence: {scope: :active}
  validates :panel_name, presence: {scope: :active}, uniqueness: {scope: [:app_type_id, :layout_name]}
  validates :panel_label, presence: {scope: :active}
  validate :access_options

  after_initialize :access_options
  before_save :set_position

  OptionTypes = [:contains, :tab, :view_options]
  attr_accessor(*OptionTypes)

  class Configuration
    def initialize(params)
      params.each { |key, value| send "#{key}=", value }
    end
  end

  class Contains < Configuration
    attr_accessor :categories, :resources
  end

  class Tab < Configuration
    attr_accessor :parent
  end

  class ViewOptions < Configuration
    attr_accessor :initial_show, :orientation, :add_item_label, :limit
  end


  def to_s
    "#{layout_name}: #{panel_label}"
  end

  def access_options

    begin
      return unless options
      o = YAML.load options
      return unless o

      OptionTypes.each do |ot|
        option_type = ot.to_s
        ot_class = "#{self.class.name}::#{option_type.camelize}".constantize
        c = o[option_type]
        if c && c.is_a?(Hash)
          self.send("#{option_type}=", ot_class.new(c))
        end
      end

#    rescue
    end
    return o
  end

  protected
    # Force a sensible position, and shuffle items down if necessary
    def set_position
      unless disabled
        if panel_position.nil?
          max_pos = self.class.active.where(app_type_id: app_type_id, layout_name: layout_name).order(panel_position: :desc).limit(1).pluck(:panel_position).first
          self.panel_position = (max_pos || 0) + 1

        else
          panels = self.class.active.where(app_type_id: app_type_id, layout_name: layout_name).order(panel_position: :asc)
          pos = panel_position + 1
          panels.where('id <> ? AND panel_position >= ?', id, panel_position).each do |p|
            p.update! panel_position: pos, current_admin: admin if p.panel_position != pos
            pos += 1
          end
        end
      end
    end


end
