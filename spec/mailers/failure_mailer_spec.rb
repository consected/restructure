# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FailureMailer, type: :mailer do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include DynamicModelSupport

  describe 'notify job failures' do
    let(:job) { 'Test Job #123' }
    let(:mail) { FailureMailer.notify_job_failure(job).deliver_now }
    it 'renders the subject' do
      expect(mail.subject).to eq('delayed_job failure')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq(['sysadmin@restructure'])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['notifications@restructure'])
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded)
        .to match("A failure occurred running a delayed_job on server #{Settings::EnvironmentName}.\r\n#{job}")
    end
  end

  describe 'test in job' do
    before :example do
      # Seeds.setup

      @user0, = create_user
      create_admin
      create_user

      import_bulk_msg_app
    end

    it 'exercises a real job failure' do
      expect do
        HandleBatchJob.perform_now('DynamicModel::ZeusBulkMessage', limit: 'fake')
      end.to raise_error(ArgumentError)
    end
  end
end
