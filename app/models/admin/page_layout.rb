class Admin::PageLayout < ActiveRecord::Base

  self.table_name = 'page_layouts'

  include AdminHandler
  include AppTyped
  include OptionsHandler

  validates :app_type_id, presence: {scope: :active}
  validates :layout_name, presence: {scope: :active}
  validates :panel_name, presence: {scope: :active}, uniqueness: {scope: [:app_type_id, :layout_name]}
  validates :panel_label, presence: {scope: :active}
  before_save :set_position

  configure :contains, with: [:categories, :resources]
  configure :tab, with: [:parent]
  configure :view_options, with: [:initial_show, :orientation, :add_item_label, :limit]
  configure :nav, with: [:links, :resources]
  configure :container, with: [:rows, :options]
  configure :view_css, with: [:classes, :selectors]

  scope :standalone, -> { where layout_name: 'standalone' }

  def to_s
    "#{layout_name}: #{panel_label}"
  end

  def self.no_master_association
    true
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
