class SaveTriggers::CreateReference < SaveTriggers::SaveTriggersBase

  def self.config_def if_extras: {}
    {
      model_name: {
        if: if_extras,
        in: "this | master",
        with: {
          field_name: "now()",
          field_name_2: "literal value",
          field_name_3: {
            this: 'field_name'
          },
          field_name_4: {
            reference_name: 'field_name'
          }
        }
      }
    }
  end

  def perform

  end

end
