# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FailureMailer, type: :mailer do
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
end
