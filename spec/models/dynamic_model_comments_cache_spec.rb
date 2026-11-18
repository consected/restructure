# frozen_string_literal: true

# Purpose: DynamicModel#set_comments_from_table copies database comments into the definition
# options, which a later migration writes back to the database. It must read the comments
# fresh (refreshing the shared cache) so a stale cached result can never be re-applied.
# The definition is built (not saved) against the always-present core `player_infos` table,
# so the examples do not depend on any dynamic model having been created earlier.
require 'rails_helper'

RSpec.describe DynamicModel, type: :model do
  let(:definition) do
    DynamicModel.new(
      name: 'Comments cache check',
      table_name: 'player_infos',
      schema_name: Admin::MigrationGenerator.table_schema_hash['player_infos'] || 'ml_app',
      field_list: 'first_name last_name'
    )
  end

  it 'forces a fresh read of the column comments when setting comments from the table' do
    expect(Admin::MigrationGenerator.table_or_view_exists?(definition.table_name)).to be true
    allow(Admin::MigrationGenerator).to receive(:column_comments).and_return([])

    definition.set_comments_from_table(force: true)

    expect(Admin::MigrationGenerator).to have_received(:column_comments).with(force: true)
  end

  it 'does not read the column comments when the comments are already configured' do
    allow(definition).to receive(:table_comments).and_return({ table: 'Already set' })
    allow(Admin::MigrationGenerator).to receive(:column_comments).and_return([])

    definition.set_comments_from_table

    expect(Admin::MigrationGenerator).not_to have_received(:column_comments)
  end
end
