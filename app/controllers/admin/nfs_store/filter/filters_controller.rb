
  module Admin::NfsStore
    module Filter
      class FiltersController < AdminController

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

      end
    end
  end
