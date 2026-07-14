# frozen_string_literal: true

require 'rails_helper'

# Tests for OptionConfigs::ExtraOptions#clean_references_def (issue #1246).
#
# clean_references_def normalizes the `references:` configuration of a dynamic
# definition (activity log / dynamic model / external identifier) and resolves
# each reference's target class via ModelReference.to_record_class_for_type.
#
# These specs cover:
# - The happy path: a resolvable reference is enriched with class metadata and
#   no warnings/errors are recorded.
# - The unresolved-reference path outside of an app type import (fixed by
#   issue #1246): the bad entry must be removed from the reference config and
#   a :warn-level notice must be recorded via failed_config so it surfaces in
#   the admin panel. Before the fix a `break` guard clause made this branch
#   unreachable, so neither removal nor the warning ever happened.
# - The unresolved-reference path *during* an app type import
#   (Admin::AppTypeImport.import_in_progress? == true): the raw entry must be
#   left untouched and silent, since forward references to not-yet-imported
#   definitions are expected and normal mid-import.
# - A regression check that :warn level never populates config_errors, since
#   config_errors triggers `raise_bad_configs`/FphsOptionsBadConfig during
#   startup's force_option_config_parse(raise_bad_configs: true).
#
# Definition-missing unresolved branch (second half of the guard):
#   unresolved = to_class.nil? || (to_class.respond_to?(:definition) && !to_class.definition)
# The first branch (to_class.nil?) is exercised by the no_such_reference_type
# examples above. The second branch covers the case where a generated
# implementation class constant still exists but its backing definition record
# has been evicted from the cache (e.g., disabled/deleted at runtime). These
# additional examples specifically target that second branch.
RSpec.describe 'OptionConfigs::ExtraOptions#clean_references_def', type: :model do
  include ActivityLogSupport
  include ModelSupport

  before :example do
    SetupHelper.setup_al_player_contact_phones
    create_user
    create_master
    let_user_create_player_contacts

    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, user: @user

    @al = create_item
  end

  let(:config) { @al.extra_log_type_config }

  it 'enriches a resolvable reference with class metadata and records no warnings or errors' do
    config.references = {
      player_contacts: { from: 'this', add: 'many' }
    }

    config.clean_references_def

    # references is normalized/singularized to a keyed hash of hashes:
    # { player_contact: { player_contact: { ...enriched conf... } } }
    refitem = config.references[:player_contact]
    expect(refitem).not_to be_nil
    ref = refitem[:player_contact]
    expect(ref[:to_model_class_name]).to eq 'PlayerContact'
    expect(ref[:to_table_name]).to eq 'player_contacts'
    expect(config.config_warnings).to be_blank
    expect(config.config_errors).to be_blank
  end

  it 'removes an unresolved reference and records a :warn notice when no app type import is in progress' do
    allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(false)

    config.references = {
      no_such_reference_type: { from: 'this', add: 'many' }
    }

    config.clean_references_def

    refitem = config.references[:no_such_reference_type]
    expect(refitem).not_to be_nil
    expect(refitem).not_to have_key(:no_such_reference_type)

    expect(config.config_warnings).not_to be_blank
    expect(config.config_warnings.last[:message]).to include('no_such_reference_type')

    # :warn must never populate config_errors - that would trip raise_bad_configs
    # and raise FphsOptionsBadConfig during startup's option config parse.
    expect(config.config_errors).to be_blank
  end

  it 'leaves an unresolved reference untouched and silent while an app type import is in progress' do
    allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(true)

    config.references = {
      no_such_reference_type: { from: 'this', add: 'many' }
    }

    config.clean_references_def

    refitem = config.references[:no_such_reference_type]
    expect(refitem[:no_such_reference_type]).to eq(from: 'this', add: 'many')
    expect(config.config_warnings).to be_blank
    expect(config.config_errors).to be_blank
  end

  # Helper shared by the two definition-missing examples below.
  # Returns an anonymous class whose .definition returns nil, simulating a
  # generated implementation class whose backing definition record has been
  # evicted from the cache after startup.
  def ghost_class_with_nil_definition
    Class.new do
      def self.definition
        nil
      end
    end
  end

  it 'removes a class-found-but-nil-definition reference and warns outside an import' do
    allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(false)

    ghost = ghost_class_with_nil_definition
    # Intercept only the synthetic key so that the lazy initialization of
    # config (which may call to_record_class_for_type for real references)
    # is not disrupted.
    allow(ModelReference).to receive(:to_record_class_for_type).and_wrap_original do |orig, arg|
      arg == :ghost_definition_ref ? ghost : orig.call(arg)
    end
    # Explicitly verify the definition-missing branch is taken (not the nil-class
    # branch): ghost is non-nil so the guard must evaluate ghost.definition.
    expect(ghost).to receive(:definition).once.and_return(nil)

    # Clear any notices accumulated during normal config initialization before
    # asserting on the notices from the manual call below.
    config.config_warnings.clear
    config.config_errors.clear

    config.references = {
      ghost_definition_ref: { from: 'this', add: 'many' }
    }

    config.clean_references_def

    refitem = config.references[:ghost_definition_ref]
    expect(refitem).not_to be_nil
    expect(refitem).not_to have_key(:ghost_definition_ref)

    expect(config.config_warnings).not_to be_blank
    expect(config.config_warnings.last[:message]).to include('ghost_definition_ref')
    expect(config.config_errors).to be_blank
  end

  it 'leaves a class-found-but-nil-definition reference untouched and silent during an app type import' do
    allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(true)

    ghost = ghost_class_with_nil_definition
    allow(ModelReference).to receive(:to_record_class_for_type).and_wrap_original do |orig, arg|
      arg == :ghost_definition_ref ? ghost : orig.call(arg)
    end
    expect(ghost).to receive(:definition).once.and_return(nil)

    config.config_warnings.clear
    config.config_errors.clear

    config.references = {
      ghost_definition_ref: { from: 'this', add: 'many' }
    }

    config.clean_references_def

    refitem = config.references[:ghost_definition_ref]
    expect(refitem[:ghost_definition_ref]).to eq(from: 'this', add: 'many')
    expect(config.config_warnings).to be_blank
    expect(config.config_errors).to be_blank
  end
end
