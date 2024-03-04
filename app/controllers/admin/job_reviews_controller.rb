# frozen_string_literal: true

class Admin::JobReviewsController < AdminController
  helper_method :queue_options
  #
  # Restart all failed jobs
  def restart_failed_jobs
    res = Messaging::JobReview.restart_failed_jobs!

    flash[:notice] = "Restarted #{res} #{'job'.pluralize(res)}"
    redirect_to admin_job_reviews_path(filter: filter_params)
  end

  #
  # Delete all failed jobs
  def delete_failed_jobs
    res = Messaging::JobReview.delete_failed_jobs!

    flash[:notice] = "Deleted #{res} #{'job'.pluralize(res)}"
    redirect_to admin_job_reviews_path(filter: filter_params)
  end

  protected

  def view_folder
    'admin/common_templates'
  end

  def filters
    {
      queue: Messaging::JobReview::ValidQueues,
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

    res = super

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

  def queue_options
    Messaging::JobReview::ValidQueues + ['delete']
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

  def show_head_info
    true
  end

  #
  # Extend the filtering of the index to cope with the Find Job form
  # @param [ActiveRecord::Relation] pm - optional
  # @return [ActiveRecord::Relation]
  def filtered_primary_model(pm = nil)
    job_id = params.dig(:filter, :job_id)
    id = params.dig(:filter, :id)
    if job_id.present?
      job = Delayed::Job.find_by_job_id(job_id)
      pm = primary_model.where(id: job&.id)
    elsif id.present?
      pm = primary_model.where(id: id)
    else
      pm ||= primary_model
    end
    super(pm)
  end
end
