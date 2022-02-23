# frozen_string_literal: true

module ViewHandlers
  module Address
    extend ActiveSupport::Concern

    PrimaryRank = 10
    SecondaryRank = 5
    InactiveRank = 0

    included do
      validates :zip, "validates/zip": true, allow_blank: true
    end

    class_methods do
      def states
        Classification::AddressState.id_value_pairs
      end

      def get_state_name(code)
        return unless code

        states[code.upcase]
      end

      def get_country_name(code)
        return unless code

        country_code = code.upcase
        country = ISO3166::Country[country_code]
        country.translations[I18n.locale.to_s] || country.name
      end

      def category
        :subjects
      end
    end

    def state_name
      self.class.get_state_name state
    end

    def country_name
      self.class.get_country_name country
    end

    protected

    # Validate state and zip for US country and region / postal code for non-US
    def handle_country
      if country
        self.country = country.downcase

        if country.downcase == 'us'
          self.region = nil
          self.postal_code = nil
        elsif region.blank? && postal_code.blank?
          errors.add :country,
                     'was not USA and province/county and postal code are blank. At least one must be entered for countries other than USA.'
          throw(:abort)
        else
          self.state = nil
          self.zip = nil
        end
      end
    end
  end
end
