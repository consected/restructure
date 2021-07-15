# frozen_string_literal: true

# Create new dynamic models (database tables) from CSV files as templates.
class Imports::ModelGeneratorsController < AdminController
  include AppTypeChange

  before_action :set_defaults
  before_action :set_model_generator, only: %i[edit analyze_csv create_model update]

  helper_method :description_editor

  #
  # Accepts an uploaded file and parses the CSV to generate field options for a dynamic model
  # These may be reviewed by the user prior to actual creation of the dynamic model
  def analyze_csv
    if params[:import_file]
      uploaded_io = params[:import_file]
      csv = uploaded_io.read
    end
    @field_types = @model_generator.analyze_csv(csv)
    num_fields = @field_types&.length

    if num_fields.nil? || num_fields == 0
      render plain: 'No fields were found in the CSV', status: 400
      return
    end

    @model_generator.save_options
    @model_generator.save!

    render plain: 'ok'
  rescue StandardError => e
    logger.warn e
    logger.warn e.backtrace.join("\n")
    render plain: e, status: 400
  end

  #
  # Create the model based on the current options configuration
  def create_model
    @model_generator.create_dynamic_model

    @dynamic_model = @model_generator.dynamic_model
    raise FphsException, 'Failed to generate the dynamic model table' unless @dynamic_model

    redirect_to edit_imports_model_generator_path(@model_generator, from_upload: 'generated_model')
  end

  private

  def set_model_generator
    @model_generator = Imports::ModelGenerator.find(params[:id])
    @model_generator.current_admin = current_admin
    @dynamic_model = object_instance&.dynamic_model
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'imports/model_generators/form_info' }
  end

  def description_editor
    :markdown
  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def primary_model
    Imports::ModelGenerator
  end

  def permitted_params
    %i[name dynamic_model_table category options description]
  end

  #
  # Just in case the file store has not been set up for this project admin,
  # create it now if necessary
  def setup_file_store
    object_instance.current_admin ||= current_admin
    return if object_instance.file_store

    object_instance.create_file_store
  end
end
