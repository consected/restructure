# frozen_string_literal: true

class Admin::JobReviewsController < AdminController
  protected

  def view_folder
    'admin/common_templates'
  end

  def filters
    {
      queue: ['default', 'nfs_store_process', 'recurring-tasks'],
      failed: ['true', 'false']
    }
  end

  def filters_on
    %i[queue failed]
  end

  def default_index_order
    { created_at: :desc }
  end

  def filter_params
    if filter_params_permitted.blank? || (filter_params_permitted.is_a?(Array) && filter_params_permitted[0].blank?)
      return nil
    end

    res = params.require(:filter).permit(filters_on)

    if res[:failed].blank?
      res.delete(:failed)
    else
      res = if res[:failed] == 'true'
              'failed_at is not null'
            else
              'failed_at is null'
            end
    end
    res
  end

  def no_edit
    false
  end

  private

  def index_params
    %i[id priority attempts handler last_error run_at locked_at failed failed_at locked_by queue created_at updated_at]
  end

  def permitted_params
    %i[priority attempts last_error run_at locked_at failed_at locked_by queue]
  end

  def human_name
    'Background Jobs'
  end
end
