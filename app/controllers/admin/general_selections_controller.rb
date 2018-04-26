class Admin::GeneralSelectionsController < AdminController


  protected

    def filters
      { item_type: GeneralSelection.item_types.map {|g| [g,g]}.to_h }
    end

    def filters_on
      [:item_type]
    end

    def default_index_order
      {updated_at: :desc}
    end
  private
    def permitted_params
      [:name, :value, :item_type, :disabled, :edit_if_set, :edit_always, :create_with, :position, :lock, :description]
    end

end
