module RankHandler
  extend ActiveSupport::Concern

  PrimaryRank = 10
  SecondaryRank = 5
  InactiveRank = 0

  included do

    after_save :handle_primary_status, if: ->{respond_to? :rank}

  end


  # A master record can only have one email and one phone with rank set to Primary
  # If a new player contact record is created or an existing record is updated with Primary rank
  # then update any other records for the master of that type (email or phone) to Secondary
  def handle_primary_status
    return if self.class.no_master_association
    if self.rank.to_i == PrimaryRank
      # logger.info "rank set as primary in contact #{self.id} for type #{self.rec_type}.
      #             Setting other records for this master to secondary if they were primary and have the type #{self.rec_type}."
      conditions = {rank: PrimaryRank, master: master}

      unless defined?(no_rec_type) && no_rec_type
        conditions[:rec_type] = self.rec_type
      end

      self.class.where(conditions).each do |a|
        # logger.info "Record #{a.id} has primary rank currently. Current ID is #{self.id}"
        if a.id != self.id
          # logger.info "Record #{a.id} has primary rank currently. Setting it to secondary"
          a.master = master
          a.rank = SecondaryRank
          a.save
          multiple_results << a
        end
      end
    end

  end

end
