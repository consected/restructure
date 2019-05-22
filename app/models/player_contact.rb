class PlayerContact < UserBase

  include UserHandler
  include RankHandler
  include Formatter::Formatters
  include RecTypeHandler

  validates :source, 'validates/source' => true, allow_blank: true
  validates :rank, presence: true


  # an informal key onto the table is the :data field
  def self.secondary_key
    :data
  end

end
