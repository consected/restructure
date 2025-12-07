# frozen_string_literal: true

class Admin::ConfigLibrariesController < AdminController
  helper_method :format_options
  before_action :set_defaults

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @all_versions = object_instance.all_versions_query
    @version_diffs = calculate_version_diffs(@all_versions)
    render partial: 'admin/common_templates/def_versions'
  end

  protected

  def calculate_version_diffs(all_versions)
    return [] if all_versions.blank?

    diffs = []
    all_versions.each_with_index do |version, idx|
      next_version = all_versions[idx + 1]
      next unless next_version

      # Compare this version with the next (older) version
      diff_data = {
        current: version,
        previous: next_version,
        changes: {}
      }

      # Compare each attribute
      version.keys.each do |key|
        next if %w[id def_version].include?(key.to_s)

        current_val = version[key].to_s.gsub("\r\n", "\n")
        previous_val = next_version[key].to_s.gsub("\r\n", "\n")

        diff_data[:changes][key] = [previous_val, current_val] if current_val != previous_val
      end

      # Skip if only timestamp fields changed
      non_timestamp_changes = diff_data[:changes].keys.reject { |k| %w[updated_at created_at].include?(k.to_s) }
      diffs << diff_data if non_timestamp_changes.present?
    end

    diffs
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'admin/config_libraries/form_info' }
  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def before_send_processor
    'config_libraries_admin_form'
  end

  def encode_options_fields
    { options: :base64 }
  end

  def filters
    {
      category: Admin::ConfigLibrary.active.pluck(:category).uniq.compact,
      format: format_options,
      name: Admin::ConfigLibrary.active.pluck(:name).uniq.compact
    }
  end

  def filters_on
    %i[category format name]
  end

  def format_options
    Admin::ConfigLibrary.valid_formats
  end

  private

  def permitted_params
    %i[name category format options disabled]
  end
end
