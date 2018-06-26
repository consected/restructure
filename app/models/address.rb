class Address < UserBase
  include UserHandler

  PrimaryRank = 10
  SecondaryRank = 5
  InactiveRank = 0

  validates :zip, "validates/zip": true, allow_blank: true
  validates :source, source: true, allow_blank: true
  validates :rank, presence: true

  before_save :handle_country
  after_save :handle_primary_status


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

    # Only one address for a master can be set as Primary
    # If a new item is added, or an existed item is updated with Primary rank
    # update the existing record(s) with Primary status to be Secondary
    def handle_primary_status

      if self.rank.to_i == PrimaryRank
        logger.info "Address rank set as primary in address #{self.id}. Setting other addresses for this master to secondary if they were primary."

        self.master.addresses.where(rank: PrimaryRank).each do |a|
          if a.id != self.id
            logger.info "Address #{a.id} has primary rank currently. Setting it to secondary"
            a.rank = SecondaryRank
            a.save
            multiple_results << a
          end
        end
      end

    end

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
