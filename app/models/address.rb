# frozen_string_literal: true

class Address < UserBase
  include UserHandler
  include RankHandler
  include ViewHandlers::Address

  validates :source, 'validates/source' => true, allow_blank: true
  validates :rank, presence: true

  before_save :handle_country

  add_model_to_list

  def no_rec_type
    true
  end

  def data
    street
  end

  def self.permitted_params
    %i[master_id country street street2 street3 city state zip region postal_code source rank rec_type]
  end
end
