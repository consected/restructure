# frozen_string_literal: true

module DICOM
  # Monkey patch the Anonymizer class with useful methods
  class Anonymizer
    #
    # Define alternative defaults for anonymizer
    # @param [Hash] tags specifies the tags to set, in the form:
    #    { tagname: { value: '', enum: true}, 'odd/tagname2': 'some value'  }
    # @param [Array] delete_tags lists the tags to delete
    # @return [<Type>] <description>
    def reset_defaults(tags, delete_tags)
      # Reshape the tags Hash into an array of tags to be set
      tags_array = []
      tags.each do |k, v|
        v = { value: v } unless v.is_a? Hash
        item = [k.to_s, v[:value], v[:enum]]
        tags_array << item
      end

      data = tags_array.transpose
      @tags = data[0]
      @values = data[1]
      @enumerations = data[2]

      # Tags to be deleted completely during anonymization
      delete_tags_hash = {}
      delete_tags.each { |tagname| delete_tags_hash[tagname.to_s] = true }
      @delete = delete_tags_hash
    end
  end
end
