# frozen_string_literal: true

module ViewHandlers
  module Subject
    extend ActiveSupport::Concern

    BestAccuracyScore = Settings::BestAccuracyScore

    included do
      validate :dates_sensible
      validates :source, 'validates/source' => true, presence: true, if: :uses_and_has_rank?

      # If the class is a dynamic definition, add a singular association, allowing a single
      # subject info to be requested for a Master. Substitutions for example use this to get
      # subject_info.last_name as opposed to subject_infos.last_name
      if respond_to? :definition
        Master.has_one definition.one_of_this_association_name,
                       -> { order(Master.subject_info_rank_order_clause) },
                       class_name: "DynamicModel::#{definition.model_class_name}",
                       foreign_key: definition.foreign_key_name,
                       primary_key: definition.primary_key_name,
                       inverse_of: :master
      end
    end

    class_methods do
      def get_rank_name(value)
        gsrn = Classification::GeneralSelection.name_for self, value, :rank
        return gsrn if gsrn

        Classification::AccuracyScore.name_for(value)
      end

      def category
        :subjects
      end
    end

    def tracker_history_id
      super if defined? super
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

    def uses_and_has_rank?
      respond_to?(:rank) && rank?
    end

    # Override the standard rank_name, to ensure correct validation, since
    # player ranks are a special case and are defined as Classification::AccuracyScore instances
    def rank_name
      self.class.get_rank_name rank if respond_to? :rank
    end

    def dates_sensible
      return true unless respond_to?(:birth_date)

      if respond_to?(:death_date) && birth_date && death_date && birth_date > death_date
        errors.add('birth date', 'and death date are not sensible')
      end
      errors.add('birth date', 'is after today') if birth_date && birth_date > DateTime.now
    end

    def subject_age
      return unless respond_to?(:birth_date) && birth_date

      @subject_age = Date.today.year - birth_date.year
      @subject_age -= 1 if Date.today < birth_date + @subject_age.years
      @subject_age
    end
  end
end
