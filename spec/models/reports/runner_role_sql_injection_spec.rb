# frozen_string_literal: true

# Purpose: Security regression spec for GitHub Issue #1077.
#
# Verifies that role names are safely quoted when substituted into report SQL
# via Reports::Runner#substitute_current_user, preventing SQL injection or
# malformed SQL when role names contain single quotes or other special characters.
#
# The vulnerability: role names were interpolated using "'#{r}'" which does not
# escape single quotes in role names (e.g. "reviewer's" -> 'reviewer's' is broken SQL).
# The fix uses Report.connection.quote(r) for safe, parameterized-style quoting.

require 'rails_helper'

RSpec.describe Reports::Runner, '#substitute_current_user' do
  include ModelSupport

  before(:each) do
    create_admin
    create_user
  end

  let(:report) do
    r = Report.new(
      name: "Security Test Report #{SecureRandom.hex(4)}",
      sql: 'select :current_user_roles as roles',
      search_attrs: ''
    )
    r.current_user = @user
    r
  end

  let(:runner) { described_class.new(report) }

  describe 'role name SQL quoting (security: issue #1077)' do
    context 'when a role name contains a single quote' do
      before do
        allow(@user).to receive_message_chain(:user_roles, :active, :pluck)
          .and_return(["reviewer's"])
      end

      it 'does not produce malformed SQL with an unescaped single quote mid-token' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        # Malformed pattern: 'reviewer's' — the apostrophe breaks the SQL string literal
        expect(result).not_to include("'reviewer's'")
      end

      it 'properly escapes the single quote using connection.quote' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        # connection.quote produces 'reviewer''s' (SQL standard escaped apostrophe)
        expect(result).to include("'reviewer''s'")
      end

      it 'wraps the result in an array[] expression' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        expect(result).to match(/array\[.*reviewer.*\]/i)
      end
    end

    context 'when a role name contains a SQL injection attempt' do
      before do
        allow(@user).to receive_message_chain(:user_roles, :active, :pluck)
          .and_return(["'; DROP TABLE users; --"])
      end

      it 'escapes the single quote so the injection payload cannot break out of the SQL string literal' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        # A bare (unescaped) '; sequence — close-quote then semicolon — would allow the payload
        # to terminate the SQL string and inject commands. When connection.quote is used, the
        # internal single quote is doubled ('' = SQL escaped '), so the '; pattern is always
        # preceded by another ' (forming ''') and can never close the string prematurely.
        # The negative lookbehind (?<!') ensures we only flag a truly unescaped quote+semicolon.
        expect(result).not_to match(/(?<!')';\s*DROP TABLE/)
      end

      it 'produces a properly escaped SQL array with the doubled-quote escape sequence' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        # connection.quote doubles internal single quotes: ' becomes '' — safe for SQL
        expect(result).to include("''; DROP TABLE")
      end
    end

    context 'when role names are normal (no special characters)' do
      before do
        allow(@user).to receive_message_chain(:user_roles, :active, :pluck)
          .and_return(%w[editor viewer])
      end

      it 'produces a valid SQL array expression with quoted role names' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        expect(result).to include("array[")
        expect(result).to include("'editor'")
        expect(result).to include("'viewer'")
      end
    end

    context 'when user has no roles' do
      before do
        allow(@user).to receive_message_chain(:user_roles, :active, :pluck)
          .and_return([])
      end

      it 'substitutes an empty array expression for an empty roles list' do
        result = runner.send(:substitute_current_user, 'select :current_user_roles as roles')
        expect(result).to include('array[]')
      end
    end

    context 'when current_user is nil' do
      before do
        report.current_user = nil
      end

      it 'substitutes NULL for all current_user placeholders' do
        result = runner.send(:substitute_current_user,
                             'select :current_user, :current_user_roles, :current_user_preference')
        expect(result).to eq('select NULL, NULL, NULL')
      end
    end
  end
end
