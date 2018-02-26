class Admin::ItemFlagNamesController < AdminController

  private
    def secure_params
      params.require(:item_flag_name).permit(:name, :item_type, :disabled)
    end
end
