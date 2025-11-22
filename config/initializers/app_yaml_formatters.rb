# frozen_string_literal: true

class String
  #
  # Dump to YAML, having first simplified the data through a JSON
  # dump and parse cycle. Use an unlimited line width to avoid
  # line breaks in the YAML output.
  # @param [Object] object
  # @return [String] YAML formatted string
  def self.yaml_dump(object)
    return unless object

    object = object.deep_stringify_keys if object.respond_to?(:deep_stringify_keys)
    h = JSON.parse(object.to_json)
    YAML.dump(h, line_width: -1)&.gsub(/^---\n/, '')
  end
end
