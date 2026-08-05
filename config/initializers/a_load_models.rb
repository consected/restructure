# frozen_string_literal: true

# Explicitly load model classes that are not eagerly loaded in development mode
# but are required by features such as report criteria select_from_model lookups
# (which rely on Resources::Models being populated).
#
# In production, config.eager_load = true handles this automatically.
# In development, lazy autoloading means these models may not be loaded before
# a report tries to look them up via Resources::Models.find_by(resource_name:).

Rails.application.config.after_initialize do
  Redcap::ProjectUser
  Redcap::ProjectAdmin
end
