class Admin::ExternalIdentifierDetailsController < AdminController

  before_action :set_type


  def show

    unless params[:do] == 'report'
      ic = @external_identifier.implementation_class

      @external_ids = []
      @assigned_count = ic.assigned.length
      @unassigned_count = ic.unassigned.length
      render 'admin_handler/index'
    end

    if params[:do] == 'report'
      rep_type = params[:rep_type]

      r = @external_identifier.usage_report(rep_type)

      unless r && r.id
        flash[:alert] = "No report named '#{@external_identifier.usage_report_name(rep_type)}' is available"
        redirect_to admin_external_identifier_detail_path(@external_identifier.id)
        return
      end

      redirect_to report_path(r)
      return
    end
  end

  def new
    @external_identifier_implementation_class = @external_identifier.implementation_class.new
    @master_count = @external_identifier.implementation_class.masters_without_assignment.count
    @external_identifier_implementation_class.assign_all_request = true if params[:all_master_records] == 'true'
  end

  def create
    cc = secure_params[:create_count]
    assign_all = secure_params[:assign_all]
    assign_all_request = secure_params[:assign_all_request]

    if assign_all_request == 'true'
      if assign_all == 'true'
        @external_identifier_items = @external_identifier.implementation_class.generate_ids_for_all_masters(current_admin)
      else
        @external_identifier_implementation_class = @external_identifier.implementation_class.new
        @master_count = @external_identifier.implementation_class.masters_without_assignment.count
        @external_identifier_implementation_class.assign_all_request = true
        flash.now[:alert] = "Check the box to confirm before submitting, or go back"
        @external_identifier_implementation_class.errors.add :assign_all, 'must be checked to submit the request'
        render 'new'
        return
      end
    else

      if cc.blank? || cc.to_i < 1
        @external_identifier_implementation_class = @external_identifier.implementation_class.new
        flash.now[:alert] = "Number of IDs to create must be at least 1"
        @external_identifier_implementation_class.errors.add :create_count, "must be at least 1"
        render 'new'
        return
      else
        @external_identifier_items = @external_identifier.implementation_class.generate_ids(current_admin, cc.to_i)
      end
    end


  end

  protected

    def set_type
      @external_identifier = ExternalIdentifier.active.find(params[:id])
    end

    def primary_model
      Admin::ExternalIdentifier
    end

    def secure_params
      # SageAssignment.new.admin_id = 1
      p = @external_identifier.name.singularize.to_sym
      params.require(p).permit(:create_count, :assign_all, :assign_all_request)
    end
end
