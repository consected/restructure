# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Allow status to be pluralized to statuses not stati
  #   inflect.plural /^(ox)$/i, '\1en'
  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  inflect.uncountable %w[data]
  # Avoid the usual pluralization, since person is a common table name
  inflect.irregular 'person', 'persons'
end
# end

# Do not use acronym inflector, since it will break our expectations
# around classify and camelize. Instead, use Settings::CaptionAcronymns,
# which will be enforced for titleize only

# ActiveSupport::Inflector.inflections(:en) do |inflect|
# end
