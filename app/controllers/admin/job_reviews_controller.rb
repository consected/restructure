class Admin::JobReviewsController < AdminController


  protected

    def view_folder
      'admin/common_templates'
    end

    def filters
      {
        queue: ['default'],
        failed: ['true', 'false']
      }
    end

    def filters_on
      [:queue, :failed]
    end

    def default_index_order
      {created_at: :desc}
    end

    def filter_params
      return nil if params[:filter].blank? || (params[:filter].is_a?( Array) && params[:filter][0].blank?)
      res = params.require(:filter).permit(filters_on)

      unless res[:failed].blank?
        if res[:failed] == 'true'
          res = 'failed_at is not null'
        else
          res = 'failed_at is null'
        end
      end
      res
    end

    def no_edit
      true
    end


  private
    def permitted_params
      [:id, :priority, :attempts, :handler, :last_error, :run_at, :locked_at, :failed, :failed_at, :locked_by, :queue, :created_at, :updated_at]
    end

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end

    def human_name
      "Background Jobs"
    end

end
