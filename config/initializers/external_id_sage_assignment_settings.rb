class Settings
  
  SageAssignment.external_id_attribute = :sage_id  
  SageAssignment.prevent_edit = true
  SageAssignment.external_id_view_formatter = 'format_sage_id'
  SageAssignment.label = 'Sage ID'

  
  # Sage Assignments need a special build, which handles the allocation of an existing item from the table
  # when an instance is created. Within the structure we have, it is necessary to override the master.sage_assignments.build
  # method to ensure everything works as expected
  # Pass the new build method in to make the association build work
  SageAssignment.add_to_app_list do
    def build att=nil
      SageAssignment.master_build_with_next_id proxy_association.owner, att
    end
  end
  
end
