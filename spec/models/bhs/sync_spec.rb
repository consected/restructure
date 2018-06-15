require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'BHS App Sync', type: :model do

  include ModelSupport
  include PlayerContactSupport
  include BhsImportConfig

  def create_item_to_sync
    bhs_id = 574

    BhsAssignment.all.each do |b|

      b.master.current_user = @user
      b.update!(bhs_id: rand(89999999)+100000000)
      # Force it to be ignored in future
      if b.master.player_infos.length == 0
        b.master.player_infos.create!
      end
    end


    m = Master.create! current_user: @user
    b = m.bhs_assignments.create! bhs_id: bhs_id
    m.activity_log__bhs_assignments.create! bhs_assignment_id: b.id, extra_log_type: :primary, item_id: b.id, return_call_availability_notes: "Created at #{DateTime.now}"
    @master = m
  end


  before :all do
    import_config

    # Ensure we have adequate access controls
    setup_access :player_infos
    setup_access :player_contacts
    create_item(data: rand(10000000000000000), rank: 10)

    setup_access :bhs_assignments
    setup_access :activity_log__bhs_assignments
    setup_access :activity_log__bhs_assignment__primary, resource_type: :activity_log_type


    create_item_to_sync

  end

  it "syncs a master ID" do

    puts "Running sync"
    `RAILS_ENV=test ./db/app_specific/sync-process/bhs-sync/sync_subject_data.sh`

    m = @master
    m.reload
    m.current_user = @user
    expect(m.player_infos.length).to eq 1
    expect(m.player_contacts.length).not_to eq 0

    al = m.activity_log__bhs_assignments.first
    expect(al.select_record_from_player_contact_phones).to eq m.player_contacts.phone.order(rank: :desc).first.data

    msg = Messaging::MessageNotification.where(item_id: al.id, item_type: al.class.name, master_id: @master.id).first
    expect(msg).to be_a Messaging::MessageNotification

  end

  it "won't sync until an activity log has been added" do
  end
end
