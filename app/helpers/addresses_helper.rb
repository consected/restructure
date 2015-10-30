module AddressesHelper

  def state_hash
    AddressState.id_value_pairs
  end
 
end
