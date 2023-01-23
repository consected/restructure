module Reports
  module ReportEditing
    extend ActiveSupport::Concern

    included do
      scope :editable_data_reports, -> { where(Arel.sql("edit_model IS NOT NULL AND edit_model <> ''")) }
    end

    class_methods do
      #
      # Editable reports can have general selections attached to them. This method allows that.
      def item_types(refresh: false)
        Rails.cache.delete('Report.item_types') if refresh

        Rails.cache.fetch('Report.item_types') do
          res = []
          editable_data_reports.each do |r|
            next if r.selection_fields.blank?

            res += r.selection_fields.split(/[^a-zA-Z0-9_]/).collect do |c|
              "report_#{r.name.id_underscore}_#{c.downcase}".to_sym
            end
          end
          res
        end
      end
    end

    # Can the results be edited?
    def editable_data?
      !edit_model.blank?
    end

    # Can add items to the results?
    def creatable_data?
      editable_data?
    end

    # If the results can be edited, what class represents each result
    def edit_model_class
      return unless editable_data?

      res = Resources::Models.find_by(table_name: edit_model)
      model_class = res[:model] if res

      if model_class
        model_class
      else
        obj_table_name = edit_model.downcase
        definition = self
        a_new_class = Class.new(ReportBase) do
          self.table_name = obj_table_name
          self.definition = definition
        end
        model_class_name = edit_model.camelize.classify
        Report.const_set(model_class_name, a_new_class)
      end
    end

    # List all configured fields for editing, although not all of these fields may actually be updatable in reality
    def all_configured_edit_fields
      @all_configured_edit_fields ||= edit_field_names.split(/[^a-zA-Z0-9_]/).reject(&:blank?).collect(&:to_sym)
    end

    # Edit fields that can be updated in a record
    def edit_fields
      all_configured_edit_fields - search_reports_fields
    end

    # List any search_reports_ fields that represent criteria to feed to another report in the UI
    def search_reports_fields
      @search_reports_fields ||= all_configured_edit_fields.select { |s| s.to_s.start_with?('search_reports_') }
    end
  end
end
