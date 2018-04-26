class Admin::ItemFlagNamesController < AdminController

  protected

  def filters
    { item_type: ItemFlagName.item_types }
  end

  def filters_on
    [:item_type]
  end



  private
    def permitted_params
      [:name, :item_type, :disabled]
    end
end
