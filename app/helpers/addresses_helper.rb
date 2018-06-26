module AddressesHelper

  def state_hash
    Classification::AddressState.id_value_pairs
  end

end
