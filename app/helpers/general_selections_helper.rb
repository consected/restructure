module GeneralSelectionsHelper

  def general_selection type
    raise "Item type not recognized" unless GeneralSelection::ItemTypes.include? type
    GeneralSelection.selector_name_value_pair(item_type: type)
  end

end
