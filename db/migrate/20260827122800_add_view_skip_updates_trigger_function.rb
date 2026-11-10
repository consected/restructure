# frozen_string_literal: true

class AddViewSkipUpdatesTriggerFunction < ActiveRecord::Migration[8.0]
  # Dummy INSTEAD OF trigger function used by dynamic model views configured with
  # `_configurations: view_skip_updates: true`, to make otherwise non-updatable
  # views appear updatable so save triggers can fire on the records - fixes #1203
  def up
    execute <<~SQL
      create or replace function ml_app.view_skip_updates()
      returns trigger
      language plpgsql
      as $function$
        begin
          return new;
        end
      $function$;
    SQL
  end

  def down
    execute 'drop function if exists ml_app.view_skip_updates() cascade;'
  end
end
