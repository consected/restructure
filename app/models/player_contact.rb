# frozen_string_literal: true

class PlayerContact < UserBase
  include UserHandler
  include ViewHandlers::Contact
end
