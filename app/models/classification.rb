# frozen_string_literal

#
# Parent for all mechanisms for classifying records
module Classification
  #
  # Get a classification class by name
  # @param [Symbol | String] name
  # @return [Classification::Class]
  def self.get_classification_type_by(name: nil, raise_exception: nil)
    res = const_get(name.to_s.classify) if name

    return res if res # .instance_of?(Module)
  rescue StandardError
    raise FphsException, 'Invalid classification type requested' if raise_exception

    nil
  end
end
