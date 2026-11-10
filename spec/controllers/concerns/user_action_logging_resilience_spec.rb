# frozen_string_literal: true

# UserActionLogging Resilience Spec (issue #1458)
#
# Reproduces a bug where `log_user_item_action` and `log_user_index_action` raise
# a NoMethodError when `object_instance`/`objects_instance.model` doesn't define
# `no_master_association` (e.g. Report::RcStageCifCopy in the original bug
# report). This masks whatever the original action/error actually was, since the
# after_action callback itself blows up.
#
# Test Coverage:
# - neither method raises NoMethodError when the class lacks no_master_association
#   or the instance lacks master
# - no_master_association is passed through to Admin::UserActionLog.create! as nil
#   (not forced) in that case, since it's only ever asserted via the create! call
#   args - Admin::UserActionLog#no_master_association is a non-persisted
#   attr_accessor, so re-querying the record from the DB can't verify this
# - master is left unset when no_master_association is true, or the instance
#   doesn't respond to :master, even if @master/object_instance/objects_instance
#   would otherwise supply one
# - master/objects_instance.first are not queried at all once a master is
#   already known, preserving the original short-circuit behaviour

require 'rails_helper'

# A plain object that mimics classes like Report::RcStageCifCopy which do not
# include AdminHandler/HandlesUserBase and therefore do not respond to
# `no_master_association` or `master`.
class UserActionLoggingBareObjectInstance # rubocop:disable Lint/EmptyClass
end

# Mimics a class that opts out of master association entirely.
class UserActionLoggingNoMasterInstance
  def self.no_master_association
    true
  end

  def master
    raise 'master should not be called when no_master_association is true'
  end
end

# Mimics a class that supports master association, used to prove master is not
# re-fetched once already known via @master.
class UserActionLoggingMasterRaisingInstance
  def self.no_master_association
    false
  end

  def master
    raise 'master should not be called when @master is already set'
  end
end

# Mimics a class that supports master association and actually returns one.
class UserActionLoggingMasterSupportingInstance
  def self.no_master_association
    false
  end

  attr_reader :master

  def initialize(master)
    @master = master
  end
end

RSpec.describe UserActionLogging, type: :controller do
  include ModelSupport

  # Use MastersController as a concrete controller that includes UserActionLogging,
  # overriding object_instance/objects_instance so tests can supply objects whose
  # classes lack `no_master_association` (and `master`), reproducing the bug's
  # conditions.
  controller(MastersController) do
    attr_accessor :bare_object_instance, :bare_objects_instance

    def object_instance
      bare_object_instance
    end

    def objects_instance
      bare_objects_instance
    end
  end

  before_each_login_user

  describe '#log_user_item_action' do
    before do
      controller.instance_variable_set(:@id, 1)
    end

    context 'when object_instance class lacks no_master_association' do
      before { controller.bare_object_instance = UserActionLoggingBareObjectInstance.new }

      it 'does not raise NoMethodError' do
        expect { controller.send(:log_user_item_action) }.not_to raise_error
      end

      it 'creates the log with no_master_association left nil and master_id nil' do
        expect(Admin::UserActionLog).to receive(:create!)
          .with(hash_including(no_master_association: nil, master_id: nil)).and_call_original

        controller.send(:log_user_item_action)
      end
    end

    context 'when no_master_association is true' do
      before { controller.bare_object_instance = UserActionLoggingNoMasterInstance.new }

      it 'does not attempt to fetch master from object_instance' do
        expect { controller.send(:log_user_item_action) }.not_to raise_error
      end
    end

    context 'when a master is already known via @master' do
      let(:master) { Master.create! current_user: @user }

      before do
        controller.instance_variable_set(:@master, master)
        controller.bare_object_instance = UserActionLoggingMasterRaisingInstance.new
      end

      it 'does not fetch master from object_instance' do
        expect { controller.send(:log_user_item_action) }.not_to raise_error
      end
    end

    context 'when no_master_association is false and object_instance responds to master' do
      let(:master) { Master.create! current_user: @user }

      before { controller.bare_object_instance = UserActionLoggingMasterSupportingInstance.new(master) }

      it 'fetches master from object_instance and records its id' do
        expect(Admin::UserActionLog).to receive(:create!)
          .with(hash_including(no_master_association: false, master_id: master.id)).and_call_original

        controller.send(:log_user_item_action)
      end
    end
  end

  describe '#log_user_index_action' do
    before do
      controller.bare_objects_instance = objects_instance_double
    end

    context 'when objects_instance.model lacks no_master_association' do
      let(:objects_instance_double) do
        double('objects_instance',
               model: UserActionLoggingBareObjectInstance,
               first: UserActionLoggingBareObjectInstance.new)
      end

      it 'does not raise NoMethodError' do
        expect { controller.send(:log_user_index_action) }.not_to raise_error
      end

      it 'creates the log with no_master_association left nil and master_id nil' do
        expect(Admin::UserActionLog).to receive(:create!)
          .with(hash_including(no_master_association: nil, master_id: nil)).and_call_original

        controller.send(:log_user_index_action)
      end
    end

    context 'when no_master_association is true' do
      let(:objects_instance_double) { double('objects_instance', model: UserActionLoggingNoMasterInstance) }

      it 'does not query objects_instance.first' do
        expect(objects_instance_double).not_to receive(:first)

        controller.send(:log_user_index_action)
      end
    end

    context 'when a master is already known via @master' do
      let(:master) { Master.create! current_user: @user }
      let(:objects_instance_double) { double('objects_instance', model: UserActionLoggingMasterRaisingInstance) }

      before { controller.instance_variable_set(:@master, master) }

      it 'does not query objects_instance.first' do
        expect(objects_instance_double).not_to receive(:first)

        controller.send(:log_user_index_action)
      end
    end

    context 'when only object_instance (no objects_instance) supports master' do
      let(:master) { Master.create! current_user: @user }
      let(:objects_instance_double) { nil }

      before { controller.bare_object_instance = UserActionLoggingMasterSupportingInstance.new(master) }

      it 'fetches master from object_instance and records its id' do
        expect(Admin::UserActionLog).to receive(:create!)
          .with(hash_including(no_master_association: false, master_id: master.id)).and_call_original

        controller.send(:log_user_index_action)
      end
    end

    context 'when both object_instance and objects_instance are present' do
      let(:master) { Master.create! current_user: @user }
      let(:objects_instance_double) { double('objects_instance', model: UserActionLoggingNoMasterInstance) }

      before { controller.bare_object_instance = UserActionLoggingMasterSupportingInstance.new(master) }

      it "lets objects_instance's no_master_association take precedence, without losing the master already found" do
        expect(Admin::UserActionLog).to receive(:create!)
          .with(hash_including(no_master_association: true, master_id: master.id)).and_call_original

        controller.send(:log_user_index_action)
      end
    end
  end
end
