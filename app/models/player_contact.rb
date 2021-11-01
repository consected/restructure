# frozen_string_literal: true

class PlayerContact < UserBase
  include UserHandler
  include ViewHandlers::Contact

  add_model_to_list

  # Add the 'nested' includes in the Contact handler
  handle_include_extras
end
