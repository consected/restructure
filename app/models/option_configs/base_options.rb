# frozen_string_literal: true

module OptionConfigs
  class BaseOptions
    include ActiveModel::Validations
    include OptionConfigs::ConfigErrors

    # Get an array of ConfigLibrary objects from the options text
    def self.config_libraries(config_obj)
      c = config_obj.options_text.dup
      return [] unless c.present?

      format = config_obj.is_a?(Report) ? :sql : :yaml

      Admin::ConfigLibrary.make_substitutions! c, format
    end

    #
    # Read an admin defs file (yaml typically) and return the string content
    # @param [String | Array] filename
    # @return [String]
    def self.read_admin_defs(filename)
      filename = [filename] if filename.is_a? String

      raise FphsException, 'Paths including .. are not allowed' if filename.join('/').include?('..')

      path = %w[app models admin defs]
      path += filename
      File.read(Rails.root.join(*path))
    end
  end
end
