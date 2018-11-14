
  module Admin::NfsStore
    module Filter
      class FiltersController < AdminController
        before_action :set_help_description
        helper_method :resource_name_options, :role_name_options, :extra_field_attributes

        protected
          def view_folder
            'admin/common_templates'
          end

          def primary_model
            NfsStore::Filter::Filter
          end


          def default_index_order
            "app_type_id asc, translate(resource_name, '__', 'ZZZZ') asc, #{Admin::UserAccessControl.priority_order}"
          end

          def filters
            rns = NfsStore::Filter::Filter.resource_names
            rnp = rns.map {|rn| rn.split('__')[0..-2].join('__') + '__%'}.uniq.reject{|rn| rn == '__%'}
            reslist = (rns + rnp).sort
            {
              app_type_id: Admin::AppType.all_by_name,
              resource_name: reslist,
              user_id: User.active.pluck(:id, :email).to_h
            }
          end

          def filters_on
            [:app_type_id, :resource_name, :user_id]
          end

          def resource_name_options
            NfsStore::Filter::Filter.resource_names
          end

          def role_name_options
            Admin::UserRole.active.role_names_by_app_name
          end

          def extra_field_attributes
            {
              app_type_id: {
                'data-filters-select': '#nfs_store_filter_filter_role_name'
              }
            }
          end

          def permitted_params
            @permitted_params = [:id, :app_type_id, :role_name, :user_id, :resource_name, :filter, :disabled, :description]
          end

          def set_help_description
            @help_description = <<EOF
<h4>Configurations</h4>
<p>All filter use Regular Expressions to match file paths.
<p>Containers with no filters defined (for the app, role or user) for the current user will always return no files.
<p>To match any file, use the filter <code>.*</code>
<p>Remember that to match a <code>.</code> (dot) character, the character must be escaped in a regex <code>\\.</code>
<p>File paths follow Unix standards. Therefore file path separators are forward-slash <code>/</code>. These characters do not need to be escaped (unlike many scripting languages that use <code>/.../</code> to indicate a regex definition)
<p>Stored and archived files to be filtered against have an initial forward-slash <code>/</code> character.
<p>Filter definitions that use the regex <code>^</code> (start of line) character must take this into account.
<p>For example, a file in the root directory of the container named <code>00000.dcm</code> will be matched by filter <code>^/0+\.dcm</code> or <code>/0+\.dcm</code> but will not be matched by <code>^0+\.dcm</code> since it does not expect to see the initial forward-slash.
EOF
            @help_description = @help_description.html_safe
          end

      end
    end
  end
