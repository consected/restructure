# frozen_string_literal: true

# Verifies that the conditions admin documentation matches the behaviour of the
# ConditionalActions / CalcActions implementation.
#
# Two kinds of check are performed:
#
# 1. Vocabulary coverage - every selection type, special record source, operator,
#    return keyword and calculate function defined in the implementation constants
#    must appear in the conditions documentation, and every operator used in a
#    documented example must exist in the implementation. This fails whenever a
#    new capability is added without documenting it.
#
# 2. Runnable examples - every conditions_*_defs.yaml file embedded in the
#    conditions documentation declares `# @runnable: true|false`. Runnable files
#    are loaded, evaluated against a fixed set of sample records and checked
#    against their declared `@expect` / `@return` result, so a documented example
#    cannot silently stop working.
#
# The sample records are described in docs/admin_reference/general/conditions.md.

require 'rails_helper'

RSpec.describe 'Conditions documentation', type: :model do
  include ModelSupport
  include ActivityLogSupport

  def self.defs_dir = Rails.root.join('app/models/admin/defs')
  def self.docs_dir = Rails.root.join('docs/admin_reference/general')

  def self.doc_pages
    %w[
      conditions.md
      conditions_record_sources.md
      conditions_operators.md
      conditions_returns.md
      conditions_scope.md
      conditions_validation.md
    ]
  end

  # Every per-pattern defs file embedded in the conditions documentation.
  # conditions_defs.yaml is the retired aggregate file and is excluded.
  def self.defs_files
    Dir.glob(defs_dir.join('conditions_*_defs.yaml'))
       .map { |p| File.basename(p) }
       .reject { |f| f == 'conditions_defs.yaml' }
       .sort
  end

  # Extract `# @key: value` annotations from a defs file
  def self.annotations(content)
    content.lines.each_with_object({}) do |line, res|
      m = line.match(/^#\s*@(\w+):\s*(.*)$/)
      res[m[1]] = m[2].strip if m
    end
  end

  def annotations(content)
    self.class.annotations(content)
  end

  let(:defs_contents) { self.class.defs_files.to_h { |f| [f, File.read(self.class.defs_dir.join(f))] } }
  let(:doc_contents) { self.class.doc_pages.to_h { |f| [f, File.read(self.class.docs_dir.join(f))] } }
  let(:documentation_corpus) { (doc_contents.values + defs_contents.values).join("\n") }

  describe 'documentation structure' do
    doc_pages.each do |page|
      it "provides #{page}" do
        expect(File.exist?(self.class.docs_dir.join(page))).to be(true),
                                                               "Expected conditions documentation page #{page}"
      end
    end

    it 'embeds every conditions defs file in a documentation page' do
      embedded = doc_contents.values.join("\n").scan(/!defs\((conditions_[^)]+\.yaml)\)/).flatten.uniq
      unreferenced = self.class.defs_files - embedded
      expect(unreferenced).to be_empty,
                              "These conditions defs files are not embedded in any documentation page:\n  " \
                              "#{unreferenced.join("\n  ")}"
    end

    it 'only embeds conditions defs files that exist' do
      embedded = doc_contents.values.join("\n").scan(/!defs\((conditions_[^)]+\.yaml)\)/).flatten.uniq
      missing = embedded.reject { |f| File.exist?(self.class.defs_dir.join(f)) }
      expect(missing).to be_empty,
                         "These embedded defs files do not exist:\n  #{missing.join("\n  ")}"
    end

    defs_files.each do |file|
      context file do
        let(:content) { File.read(self.class.defs_dir.join(file)) }

        it 'declares whether it is runnable' do
          expect(annotations(content)['runnable']).to be_in(%w[true false]),
                                                      "#{file} must declare '# @runnable: true' or " \
                                                      "'# @runnable: false' so the documentation harness " \
                                                      'knows whether to evaluate it'
        end

        it 'is valid YAML' do
          expect { YAML.safe_load(content, aliases: true) }.not_to raise_error
        end

        it 'declares an expected outcome when runnable' do
          ann = annotations(content)
          next unless ann['runnable'] == 'true'

          declared = ann.keys & %w[expect return return_json return_class]
          expect(declared.length).to eq(1),
                                     "#{file} must declare exactly one of @expect, @return, @return_json or " \
                                     "@return_class - found #{declared.inspect}"
        end
      end
    end
  end

  describe 'vocabulary coverage' do
    def expect_documented(terms, description)
      undocumented = terms.map(&:to_s).reject { |t| documentation_corpus.include?(t) }
      expect(undocumented).to be_empty,
                              "#{description} not covered by the conditions documentation:\n  " \
                              "#{undocumented.join("\n  ")}"
    end

    it 'documents every selection type' do
      expect_documented CalcActions::Common::SelectionTypes, 'Selection types'
    end

    it 'documents every special record source' do
      expect_documented CalcActions::Calculate::NonJoinTableNames, 'Special record sources / reserved keys'
    end

    it 'documents every non-query record source' do
      expect_documented CalcActions::NonQueryCondition::NonQueryTableNames, 'Non-query record sources'
    end

    it 'documents every return keyword' do
      expect_documented CalcActions::Calculate::ReturnTypes, 'Return keywords'
    end

    it 'documents every calculate function' do
      expect_documented CalcActions::NonQueryCondition::ValidCalculateFunctions, 'Calculate functions'
    end

    it 'documents every query operator' do
      operators = CalcActions::Common::ValidExtraConditions +
                  CalcActions::Common::ValidExtraConditionsArrays
      expect_documented operators, 'Query condition operators'
    end

    it 'documents every in-memory operator' do
      operators = CalcActions::NonQueryCondition::SimpleConditions +
                  CalcActions::Common::UnaryConditions
      expect_documented operators, 'In-memory condition operators'
    end

    it 'only uses operators that the implementation supports' do
      valid = CalcActions::Common::ValidExtraConditions +
              CalcActions::Common::ValidExtraConditionsArrays +
              CalcActions::NonQueryCondition::SimpleConditions

      used = defs_contents.values.join("\n").scan(/^\s*condition:\s*'?([^'\n#]+?)'?\s*$/).flatten.map(&:strip)
      invalid = used.uniq - valid
      expect(invalid).to be_empty,
                         "Documented examples use operators the implementation does not support:\n  " \
                         "#{invalid.join("\n  ")}"
    end
  end

  describe 'runnable examples' do
    before :example do
      create_user
      create_master
      let_user_create_player_contacts

      setup_access :activity_log__player_contact_phones
      setup_access :addresses
      setup_access :player_infos
      setup_access :item_flags
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type

      setup_sample_records
      setup_sample_role
      setup_sample_references
    end

    # A single master record holding the sample data the documented examples refer to
    def setup_sample_records
      @activity_log = create_item
      @activity_log.current_user = @user
      @master = @activity_log.master
      @master.current_user = @user

      @address = @master.addresses.create!(city: 'portland', state: 'OR', zip: '12345',
                                           rank: 10, rec_type: 'home', source: 'nflpa')

      @player_info = @master.player_infos.create!(first_name: 'Flag', last_name: 'Check',
                                                  birth_date: Date.today - 30.years,
                                                  rank: 10, source: 'nflpa')
      @player_info.current_user = @user
      flag_name = Classification::ItemFlagName.create!(name: "flag-#{SecureRandom.hex(6)}",
                                                       item_type: 'player_info',
                                                       current_admin: @admin)
      @player_info.item_flags.create!(item_flag_name: flag_name, user: @user)

      # Three entries whose select_who values are used by the and_latest_matches example.
      # who_2 is created last so that it is the latest of the three.
      @activity_log_latest = nil
      3.times do |i|
        @activity_log_latest = create_in_master(select_who: "who_#{i}")
      end

      @activity_log_with_trigger_results = create_in_master
      @activity_log_with_trigger_results.save_trigger_results = {
        result1: { res_value: 'element result value' }
      }
      @activity_log_with_trigger_results.trigger_variables = {
        contact_record: 'sample@example.com',
        nested_var: { status: nil }
      }

      # An entry whose select_who has just been changed, so previous_value_of_ has a value
      @activity_log_changed = create_in_master
      @activity_log_changed.update!(select_who: 'reviewer', current_user: @user, master_id: @master.id)
    end

    def create_in_master(attrs = {})
      item = create_item
      item.update!(attrs.merge(current_user: @user, master_id: @master.id))
      item.current_user = @user
      item
    end

    def setup_sample_role
      previous = Admin::UserRole.order(id: :desc).limit(1).pluck(:id).first
      Admin::UserRole.where(role_name: 'test', app_type: @user.app_type)
                     .update_all(role_name: "test-old-#{previous}")
      Admin::UserRole.create! app_type: @user.app_type, user: @user, role_name: 'test', current_admin: @admin
      @user.reload
    end

    # References used by the this_references, referring_record and ids_referencing examples
    def setup_sample_references
      config = @activity_log.extra_log_type_config
      config.references = {
        address: { from: 'master', add: 'one_to_master' },
        activity_log__player_contact_phone: { from: 'this', add: 'many' }
      }
      OptionConfigs::ExtraOptionConfigs::References.reprocess(config)

      @referencing_activity_log = create_in_master
      ModelReference.create_with @referencing_activity_log, @address, force_create: true
      @referencing_activity_log.reset_model_references

      @referring_activity_log = create_in_master
      @referred_activity_log = create_in_master
      ModelReference.create_with @referring_activity_log, @referred_activity_log, force_create: true
      @referring_activity_log.reset_model_references
      @referred_activity_log.reset_model_references
    end

    def sample_instances
      {
        'activity_log' => @activity_log,
        'activity_log_changed' => @activity_log_changed,
        'activity_log_latest' => @activity_log_latest,
        'activity_log_with_trigger_results' => @activity_log_with_trigger_results,
        'referencing_activity_log' => @referencing_activity_log,
        'referred_activity_log' => @referred_activity_log,
        'player_info' => @player_info
      }
    end

    defs_files.each do |file|
      content = File.read(defs_dir.join(file))
      ann = annotations(content)
      next unless ann['runnable'] == 'true'

      it "evaluates the documented example in #{file} as documented" do
        config = YAML.safe_load(content, aliases: true).deep_symbolize_keys
        instance = sample_instances.fetch(ann['instance'] || 'activity_log')
        conditional_actions = ConditionalActions.new config, instance

        if ann.key?('expect')
          expect(conditional_actions.calc_action_if).to eq(ann['expect'] == 'true')
        elsif ann.key?('return')
          expect(conditional_actions.get_this_val.to_s).to eq(ann['return'])
        elsif ann.key?('return_json')
          expect(conditional_actions.get_this_val).to eq(JSON.parse(ann['return_json']))
        else
          expect(conditional_actions.get_this_val).to be_a(ann['return_class'].constantize)
        end
      end
    end
  end
end
