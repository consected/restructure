class Admin::SageAssignmentsController < ApplicationController

  include AdminControllerHandler

  def index
    @sage_assignments = []
    @assigned_count = SageAssignment.assigned.length
    @unassigned_count = SageAssignment.unassigned.length
    
  end
  
  def show 
    if params[:id] == 'report'
      rep_type = params[:rep_type]
      r = Report.where(name: "Sage #{rep_type}", disabled: false).first
      
      unless r && r.id
        flash[:alert] = "No report named Sage Assignments is available"
        redirect_to admin_sage_assignments_path
        return
      end
      
      redirect_to report_path(r)
      return
    end
  end
  
  def new
    @sage_assignment = SageAssignment.new 
  end
  
  def create
    cc = secure_params[:create_count]
    
    if cc.blank? || cc.to_i < 1
      @sage_assignment = SageAssignment.new 
      flash.now[:alert] = "Number of IDs to create must be at least 1"
      @sage_assignment.errors.add :create_count, "must be at least 1"
      render 'new'
      return
    end  
    
    @sage_assignments = SageAssignment.generate_ids(current_admin, cc.to_i)
    
  end
  
  protected

    def secure_params
      params.require(:sage_assignment).permit(:create_count)
    end
end
