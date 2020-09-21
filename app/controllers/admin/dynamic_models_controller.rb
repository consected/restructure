# frozen_string_literal: true

class Admin::DynamicModelsController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name
  before_action :set_help_description
  before_action :set_defaults
  helper_method :view_folder
  after_action :routes_reload, only: %i[update create]

  protected

  def routes_reload
    DynamicModel.routes_reload
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = {}
    @show_extra_help_info[:title] = 'Options'
    example = ExtraOptions.top_level_defs
    example = example.merge('default' => DynamicModelOptions.attr_defs.deep_stringify_keys)

    @show_extra_help_info[:text] = example.to_yaml
  end

  def filters
    {
      category: DynamicModel.categories
    }
  end

  def filters_on
    [:category]
  end

  def set_help_description
    @help_description = <<~EOF

      <h4>Configurations</h4>
      <p><b>Table key name</b> is the field used to uniquely identify a record when retrieving it to be viewed or edited. It may be unrelated to the relationship between this item and a master record.</p>
      <p><b>Primary key name</b> is the field that a master record may use to reference this record.</p>
      <p><b>Foreign key name</b> is the field used to match with a master record. Typically this is master_id, but may be one of the other fields on that table. If blank, then there is no connection to master records, but the table can be used for lookups in forms using a field <i>select_record_from_table_...</i></p>
      <br/>
      <h4>Creating a dynamic model table</h4>
      <p>From the command line, run</p>
      <p><code>db/table_generators/generate.sh dynamic_models_table create [table name pluralized] [field names ...] </code></p>
    EOF
    @help_description = @help_description.html_safe
  end

  def view_folder
    'admin/common_templates'
  end

  def permitted_params
    @permitted_params = %i[id name table_name schema_name category
                           table_key_name primary_key_name
                           foreign_key_name result_order field_list position options
                           description disabled]
  end
end
