class PlayerContactsController < UserBaseController

  include MasterHandler

  protected
    def edit_form
      'common_templates/edit_form'
    end

end
