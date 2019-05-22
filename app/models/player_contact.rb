class PlayerContact < UserBase

  include UserHandler
  include RankHandler

  def self.valid_rec_types
    %i(phone email)
  end

  include Formatter::Phone
  include Formatter::Email
  include RecTypeHandler

  validates :source, 'validates/source' => true, allow_blank: true
  validates :rank, presence: true



  # an informal key onto the table is the :data field
  def self.secondary_key
    :data
  end


  private


end
