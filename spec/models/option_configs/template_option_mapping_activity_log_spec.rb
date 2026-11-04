# frozen_string_literal: true

# The activity log primary and blank log template state is installed from two places: the master
# page skeleton, and the state-only render that accompanies an edit form or a lazy template_config
# fetch. Both write the same live state slot (and the v0 alias), so the state-only mapping must
# agree with the skeleton. In particular, the item list must include the tracker_history_id
# field, otherwise opening a form for a log removes the "Related tracker items" panel from every
# rendered log of that type.

require 'rails_helper'

RSpec.describe 'TemplateOptionMapping activity log item lists', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include ActivityLogSupport
  include OptionsSupport

  before_all do
    @user0, = create_user
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    generate_test_activity_log
  end

  let(:definition) { ActivityLog.active.find_by(name: 'activity_log_player_contact_emails') }
  let(:implementation_class) { definition.implementation_class }

  def mapped_item_list(option_name)
    option_type_config = definition.option_configs.find { |c| c.name == option_name }
    OptionConfigs::TemplateOptionMapping.activity_log_mapping(definition, option_type_config, @user)[:item_list]
  end

  it 'includes the tracker history field for the primary option, matching the page skeleton' do
    expect(mapped_item_list(:primary).map(&:to_sym)).to eq implementation_class.view_attribute_list
    expect(mapped_item_list(:primary).map(&:to_sym)).to include :tracker_history_id
  end

  it 'includes the tracker history field for the blank log option, matching the page skeleton' do
    expect(mapped_item_list(:blank_log).map(&:to_sym)).to eq implementation_class.view_blank_log_attribute_list
    expect(mapped_item_list(:blank_log).map(&:to_sym)).to include :tracker_history_id
  end
end
