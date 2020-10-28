# frozen_string_literal: true

class UpdateCategoryInExternalIdentifiers < ActiveRecord::Migration[5.2]
  def self.up
    ExternalIdentifier.update_all("category = split_part(name, '_', 1)")
  end
end
