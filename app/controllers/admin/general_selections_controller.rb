# frozen_string_literal: true

class Admin::GeneralSelectionsController < AdminController
  protected

  def filters
    app_type = current_user&.app_type
    item_types = if app_type
                   app_type.associated_general_selections.map(&:item_type)
                 else
                   Classification::GeneralSelection.item_types
                 end

    { item_type: item_types.map { |g| [g, g] }.to_h }
  end

  def filters_on
    [:item_type]
  end

  def default_index_order
    { updated_at: :desc }
  end

  private

  def permitted_params
    %i[name value item_type disabled edit_if_set edit_always create_with position lock description]
  end
end
