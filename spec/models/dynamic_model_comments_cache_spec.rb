# frozen_string_literal: true

# Purpose: DynamicModel#set_comments_from_table copies database comments into the definition
# options, which a later migration writes back to the database. It must read the comments
# fresh (refreshing the shared cache) so a stale cached result can never be re-applied.
require 'rails_helper'

RSpec.describe DynamicModel, type: :model do
  it 'forces a fresh read of the column comments when setting comments from the table' do
    definition = DynamicModel.active.detect(&:table_or_view_ready?)
    skip 'No active dynamic model with an existing table' unless definition

    allow(Admin::MigrationGenerator).to receive(:column_comments).and_return([])

    definition.set_comments_from_table(force: true)

    expect(Admin::MigrationGenerator).to have_received(:column_comments).with(force: true)
  end
end
