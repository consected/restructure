# frozen_string_literal: true

class Admin::JobReviewsController < AdminController
  protected

  def view_folder
    'admin/common_templates'
  end

  def filters
    {
      queue: %w[default nfs_store_process recurring-tasks redcap batch],
      failed: %w[true false]
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
      res[:failed_at] = if res[:failed] == 'true'
                          'is not null'
                        else
                          'is null'
                        end
    end
    res
  end

  def no_edit
    false
  end

  private

  def index_params
    %i[id priority attempts handler run_at locked_at failed failed_at locked_by queue created_at updated_at last_error]
  end

  def permitted_params
    %i[priority attempts last_error run_at locked_at failed_at locked_by queue]
  end

  def human_name
    'Background Jobs'
  end
end
