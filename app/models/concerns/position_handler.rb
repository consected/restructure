# frozen_string_literal: true

#
# Handle administration of position for admin items using it,
# to automatically keep numbers sequential (although not necessarily without gaps)
module PositionHandler
  extend ActiveSupport::Concern

  included do
    before_save :set_position
  end

  class_methods do
    def position_attribute
      :position
    end
  end

  protected

  #
  # Position within a grouping of which attributes?
  def position_group
    { app_type_id: app_type_id }
  end

  #
  # Force a sensible position in the list, and shuffle items down if necessary
  def set_position
    return if disabled

    position_attribute = self.class.position_attribute.to_s

    if attributes[position_attribute].nil?
      max_pos = self.class.active
                    .where(position_group)
                    .order(position_attribute => :desc)
                    .limit(1)
                    .pluck(position_attribute)
                    .first
      attributes[position_attribute] = (max_pos || 0) + 1
    else
      pos = attributes[position_attribute] + 1
      other_items = self.class.active
                        .where(position_group)
                        .where.not(id: id)
                        .where("#{position_attribute} >= ?", attributes[position_attribute])
                        .order(position_attribute => :asc)

      other_items.each do |p|
        p.update! position_attribute => pos, current_admin: admin if p.attributes[position_attribute] != pos
        pos += 1
      end
    end
  end
end
