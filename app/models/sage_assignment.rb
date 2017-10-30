class SageAssignment < UserBase
  include UserHandler
  include ExternalIdHandler

  validates :sage_id, presence: true,  length: {is: 10}
  validate :sage_id_tests
  default_scope -> {order id: :desc}
  after_save :return_all


  def allows_nil_master?
    true
  end


  def return_all
    self.multiple_results = self.master.sage_assignments.all if self.master
  end


  protected


    def sage_id_tests

      if persisted? && sage_id_changed?
        errors.add :sage_id, "can not be changed"
      end

      if persisted? && master_id_changed? && !master_id_was.nil?
        errors.add :master, "record this sage ID is associated with can not be changed"
      end

    end

    def creatable_without_user
      true
    end

end
