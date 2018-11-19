class Address < UserBase
  include UserHandler
  include RankHandler

  validates :zip, "validates/zip": true, allow_blank: true
  validates :source, 'validates/source' => true, allow_blank: true
  validates :rank, presence: true

  before_save :handle_country

  def no_rec_type
    true
  end

  def data
    self.street
  end

  def self.states
    Classification::AddressState.id_value_pairs
  end

  def self.get_state_name code
    return unless code
    states[code.upcase]
  end

  def state_name
    Address.get_state_name self.state
  end

  def self.get_country_name code
    return unless code
    country_code = code.upcase
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name

  end

  def country_name
    Address.get_country_name self.country
  end

  def self.permitted_params
    [:master_id, :country,  :street, :street2, :street3, :city, :state, :zip, :region, :postal_code, :source, :rank, :rec_type]
  end


  protected

    # Validate state and zip for US country and region / postal code for non-US
    def handle_country
      if country
        self.country = country.downcase

        if country.downcase == 'us'
          self.region = nil
          self.postal_code = nil
          return true
        else
          if region.blank? && postal_code.blank?
            self.errors.add :country, "was not USA and province/county and postal code are blank. At least one must be entered for countries other than USA."
            return false
          else
            self.state = nil
            self.zip = nil

            return true
          end
        end

      else
        true
      end
    end

end
