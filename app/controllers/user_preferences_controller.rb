# frozen_string_literal: true

class UserPreferencesController < UserBaseController
  include MasterHandler
  include FilterUtils

  helper_method :filter_params_hash

  protected

  def edit_form
    'common_templates/edit_form'
  end

  def filters_on
    []
  end

  def edit_form_extras
    helpers.user_preferences_form_options
  end
end
