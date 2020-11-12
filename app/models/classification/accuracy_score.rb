# frozen_string_literal: true

class Classification::AccuracyScore < ActiveRecord::Base
  self.table_name = 'accuracy_scores'
  include AdminHandler
  include SelectorCache

  default_scope { order :value }

  before_validation :prevent_value_change, on: :update
  validates :name, presence: true
  validates :value, presence: true
  validate :value_not_already_taken

  def full_label
    "#{value} - #{name}"
  end

  protected

  def prevent_value_change
    if value_changed? && persisted?
      errors.add(:value, 'change not allowed!')
      # throw(:abort)
    end
  end

  def value_not_already_taken
    errors.add :accuracy_score, "(#{value}) has already been set" if already_taken :value
  end
end
