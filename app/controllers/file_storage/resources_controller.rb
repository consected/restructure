class FileStorage::ResourcesController < UserBaseController

  include MasterHandler

  protected
    def edit_form
      'file_storage/resources/form'
    end

  end
