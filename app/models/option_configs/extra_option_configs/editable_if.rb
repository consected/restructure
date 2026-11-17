# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for editable_if access control condition.
    # Schema docs: docs/admin_reference/general/editable_if.md
    # Implemented as an IfCondition-backed config object rather than a raw Hash
    # so validation and hash-like behavior come from the shared IfCondition class.
    class EditableIf < IfCondition
      def editable_if
        conditions
      end
    end
  end
end
