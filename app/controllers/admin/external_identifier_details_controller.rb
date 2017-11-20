class Admin::ExternalIdentifierDetailsController < ApplicationController

  include AdminControllerHandler

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
  end

  def create
    cc = secure_params[:create_count]

    if cc.blank? || cc.to_i < 1
      @external_identifier_implementation_class = @external_identifier.implementation_class.new
      flash.now[:alert] = "Number of IDs to create must be at least 1"
      @external_identifier_implementation_class.errors.add :create_count, "must be at least 1"
      render 'new'
      return
    end

    @external_identifier_items = @external_identifier.implementation_class.generate_ids(current_admin, cc.to_i)

  end

  protected

    def set_type
      @external_identifier = ExternalIdentifier.active.find(params[:id])
    end

    def secure_params
      params.require(:sage_assignment).permit(:create_count)
    end
end
