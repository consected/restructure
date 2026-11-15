module ImportsHelper
  # Build a clear field mismatch error for import form builders.
  def unmatched_import_field_error(field_name)
    name = field_name.to_s
    match = name.match(/\Aimports_import\[([^\]]+)\]\z/)
    name = match[1] if match

    "The field #{name} was not matched. Check the model is up to date and server configuration has been refreshed"
  end
end
