# frozen_string_literal: true

module AddressesHelper
  def state_hash
    Classification::AddressState.id_value_pairs
  end

  def country_hash
    ISO3166::Country.translations
  end

  def state_hash_lower_keys
    state_hash.transform_keys(&:downcase)
  end

  def country_hash_lower_keys
    country_hash.transform_keys(&:downcase)
  end
end
