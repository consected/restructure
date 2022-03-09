# frozen_string_literal: true

class Admin::GeneralSelectionsController < AdminController
  protected

  def filters
    app_type = current_user&.app_type
    item_types = app_type.associated_general_selections.map(&:item_type) if app_type
    item_types = Classification::GeneralSelection.item_types unless item_types&.present?

    { item_type: item_types.map { |g| [g, g] }.to_h }
  end

  def filters_on
    [:item_type]
  end

  private

  def permitted_params
    %i[name value item_type disabled edit_if_set edit_always create_with lock position description]
  end
end
