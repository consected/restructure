# frozen_string_literal: true

module ViewHandlers
  module Subject
    extend ActiveSupport::Concern

    BestAccuracyScore = 12

    included do
      validate :dates_sensible
      validates :source, 'validates/source' => true, presence: true, if: :rank?
    end

    class_methods do
      def get_rank_name(value)
        Classification::AccuracyScore.name_for(value)
      end
    end

    def accuracy_rank
      if rank && rank > BestAccuracyScore
        rank * -1
      elsif !rank
        nil
      else
        rank
      end
    end

    def accuracy_score_name
      rank_name
    end

    # Override the standard rank_name, to ensure correct validation, since
    # player ranks are a special case and are defined as Classification::AccuracyScore instances
    def rank_name
      self.class.get_rank_name rank if respond_to? :rank
    end

    def dates_sensible
      errors.add('birth date', 'and death date are not sensible') if birth_date && death_date && birth_date > death_date
      errors.add('birth date', 'is after today') if birth_date && birth_date > DateTime.now
    end
  end
end
