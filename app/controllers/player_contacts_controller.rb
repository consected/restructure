# frozen_string_literal: true

class PlayerContactsController < UserBaseController
  include MasterHandler

  protected

  def edit_form
    'common_templates/edit_form'
  end

  def edit_form_extras
    {
      view_options: {
        view_handlers: ['contact']
      }
    }
  end
end
