class Admin::ItemFlagNamesController < AdminController

  protected

    def view_folder
      'admin/common_templates'
    end


    def filters
      { item_type: Classification::ItemFlagName.item_types }
    end

    def filters_on
      [:item_type]
    end



  private
    def permitted_params
      [:name, :item_type, :disabled]
    end
end
