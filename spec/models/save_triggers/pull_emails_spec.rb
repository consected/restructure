# frozen_string_literal: true

# Tests for SaveTriggers::PullEmails save trigger.
#
# This save trigger reads MIME-encoded email files (e.g. captured by AWS SES
# and stored in an S3 bucket) and exposes their key fields (from, to, cc,
# bcc, subject, body, headers) to inner save triggers via trigger_variables.
# After successful processing each email may be moved to a different
# location (an S3 prefix or filesystem path) or deleted, so that it is
# not processed twice.
#
# These tests use mocked endpoints — Aws::S3::Client is stubbed via
# `Aws::S3::Client.new(stub_responses: true)` and a temporary directory is
# used for the filesystem source. No real AWS or filesystem outside tmp
# is required.
#
# See GitHub issue consected/restructure#1109.
require 'rails_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe SaveTriggers::PullEmails, type: :model do
  include ModelSupport
  include ActivityLogSupport

  # Build a simple MIME-encoded email body for use as a fake SES file.
  # If `attachments:` is provided as an array of {filename:, content:, mime_type:},
  # they are added as MIME attachments.
  def build_mime_email(from:, to:, subject:, body:, cc: nil, bcc: nil, attachments: nil)
    mail = Mail.new do
      from from
      to to
      cc cc if cc
      bcc bcc if bcc
      subject subject
      body body
    end
    Array(attachments).each do |a|
      mail.add_file(filename: a[:filename], content: a[:content])
      mail.attachments[a[:filename]].content_type = a[:mime_type] if a[:mime_type]
    end
    mail.to_s
  end

  before :example do
    SetupHelper.setup_al_player_contact_phones
    res = SetupHelper.setup_al_gen_tests 'Test Pull Emails', 'test_pull_emails', 'player_contact'
    create_user
    @master = create_master
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_al_for_resource_name(res.resource_name, master: @master)
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user

    @email1 = build_mime_email(
      from: 'sender1@example.com',
      to: 'inbox@study.example.org',
      cc: 'cc1@example.com',
      subject: 'Hello world',
      body: 'This is the first test email body.'
    )
    @email2 = build_mime_email(
      from: 'sender2@example.com',
      to: 'inbox@study.example.org',
      bcc: 'bcc2@example.com',
      subject: 'Second message',
      body: 'Second body content.'
    )
  end

  describe 'S3 source (mocked)' do
    let(:bucket) { 'test-ses-bucket' }
    let(:prefix) { 'inbox/' }
    let(:processed_prefix) { 'processed/' }

    let(:stub_client) do
      Aws::S3::Client.new(stub_responses: true, region: 'us-east-1')
    end

    before do
      # Stub list_objects_v2 to return two email keys
      stub_client.stub_responses(:list_objects_v2,
                                 contents: [
                                   { key: "#{prefix}email1.eml" },
                                   { key: "#{prefix}email2.eml" }
                                 ])

      # Stub get_object to return our MIME bodies, keyed by request key
      stub_client.stub_responses(:get_object, lambda { |context|
        case context.params[:key]
        when "#{prefix}email1.eml" then { body: @email1 }
        when "#{prefix}email2.eml" then { body: @email2 }
        else { body: '' }
        end
      })

      # Track copy and delete operations
      @copies = []
      @deletes = []
      stub_client.stub_responses(:copy_object, lambda { |context|
        @copies << context.params
        { copy_object_result: { etag: '"abc"', last_modified: Time.now } }
      })
      stub_client.stub_responses(:delete_object, lambda { |context|
        @deletes << context.params
        {}
      })

      allow_any_instance_of(SaveTriggers::PullEmails)
        .to receive(:aws_s3_client).and_return(stub_client)
    end

    it 'iterates each email and exposes parsed fields via trigger_variables' do
      seen = []
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
        seen << trigger.instance_variable_get(:@item).trigger_variables[:email].dup
      end

      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(seen.length).to eq 2
      expect(seen.map { |e| e[:from] }).to contain_exactly('sender1@example.com', 'sender2@example.com')
      first = seen.find { |e| e[:from] == 'sender1@example.com' }
      expect(first[:to]).to eq ['inbox@study.example.org']
      expect(first[:cc]).to eq ['cc1@example.com']
      expect(first[:subject]).to eq 'Hello world'
      expect(first[:body]).to include 'first test email body'
    end

    it 'accumulates an array of all processed emails as variables.emails' do
      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      emails = @al.trigger_variables[:emails]
      expect(emails).to be_an(Array)
      expect(emails.length).to eq 2
      expect(emails[0][:subject]).to eq 'Hello world'
      expect(emails[1][:subject]).to eq 'Second message'

      # Ensure substitution syntax works for indexed access
      result = Formatter::Substitution.substitute('{{variables.emails.0.subject}}',
                                                  data: @al, ignore_missing: true)
      expect(result).to eq 'Hello world'
      result = Formatter::Substitution.substitute('{{variables.emails.1.from}}',
                                                  data: @al, ignore_missing: true)
      expect(result).to eq 'sender2@example.com'
    end

    it 'runs on_email triggers per email with substitution from email fields' do
      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix },
        on_email: [
          { update_this: { with: { notes: '{{variables.email.subject}}' } } }
        ]
      }

      # Stub trigger class lookup so we can capture per-email behaviour without
      # running real update_this against the model.
      executed = []
      fake_trigger_class = Class.new do
        define_method(:initialize) do |cfg, item|
          @cfg = cfg
          @item = item
        end
        define_method(:perform_with_lifecycle) do
          executed << Formatter::Substitution.substitute(@cfg[:with][:notes], data: @item, ignore_missing: true)
          true
        end
      end
      allow(OptionConfigs::ExtraOptions).to receive(:trigger_class)
        .with(:update_this).and_return(fake_trigger_class)

      SaveTriggers::PullEmails.new(config, @al).perform

      expect(executed).to contain_exactly('Hello world', 'Second message')
    end

    it 'limits the number of emails processed' do
      processed = []
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
        processed << trigger.instance_variable_get(:@item).trigger_variables[:email][:from]
      end

      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix },
        limit: 1
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(processed.length).to eq 1
    end

    it 'moves processed emails to a different prefix' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix },
        after_processing: { move_to: { prefix: processed_prefix } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      copied_keys = @copies.map { |p| [p[:bucket], p[:key], p[:copy_source]] }
      expect(copied_keys).to include([bucket, "#{processed_prefix}email1.eml", "#{bucket}/#{prefix}email1.eml"])
      expect(copied_keys).to include([bucket, "#{processed_prefix}email2.eml", "#{bucket}/#{prefix}email2.eml"])
      expect(@deletes.map { |p| p[:key] })
        .to contain_exactly("#{prefix}email1.eml", "#{prefix}email2.eml")
    end

    it 'deletes processed emails when delete: true' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix },
        after_processing: { delete: true }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(@copies).to be_empty
      expect(@deletes.map { |p| p[:key] })
        .to contain_exactly("#{prefix}email1.eml", "#{prefix}email2.eml")
    end

    it 'does not move or delete an email whose triggers raised' do
      call_count = 0
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do
        call_count += 1
        raise FphsException, 'boom' if call_count == 1

        true
      end

      config = {
        source: { type: 's3', bucket: bucket, prefix: prefix },
        after_processing: { delete: true }
      }
      expect do
        SaveTriggers::PullEmails.new(config, @al).perform
      end.not_to raise_error

      # Only one email should be deleted (the one that succeeded)
      expect(@deletes.length).to eq 1
    end
  end

  describe 'filesystem source' do
    let(:tmpdir) { Dir.mktmpdir('pull_emails_spec') }
    let(:processed_dir) { File.join(tmpdir, 'processed') }

    before do
      FileUtils.mkdir_p(processed_dir)
      File.write(File.join(tmpdir, 'a.eml'), @email1)
      File.write(File.join(tmpdir, 'b.eml'), @email2)
    end

    after do
      FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir)
    end

    it 'reads emails from a directory and exposes parsed fields' do
      seen = []
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
        seen << trigger.instance_variable_get(:@item).trigger_variables[:email].dup
      end

      config = {
        source: { type: 'filesystem', path: tmpdir }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(seen.length).to eq 2
      expect(seen.map { |e| e[:subject] }).to contain_exactly('Hello world', 'Second message')
    end

    it 'moves processed emails to another directory' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = {
        source: { type: 'filesystem', path: tmpdir },
        after_processing: { move_to: { path: processed_dir } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(Dir.children(tmpdir).sort).to eq ['processed']
      expect(Dir.children(processed_dir).sort).to eq ['a.eml', 'b.eml']
    end

    it 'deletes processed emails when delete: true' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = {
        source: { type: 'filesystem', path: tmpdir },
        after_processing: { delete: true }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(Dir.children(tmpdir)).to eq ['processed']
    end

    it 'leaves source emails untouched when after_processing is not set' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = { source: { type: 'filesystem', path: tmpdir } }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(Dir.children(tmpdir).sort).to eq ['a.eml', 'b.eml', 'processed']
    end
  end

  describe 'capturing attachments to a filestore container' do
    let(:tmpdir) { Dir.mktmpdir('pull_emails_attach_spec') }

    before do
      File.write(File.join(tmpdir, 'a.eml'), build_mime_email(
                                               from: 'sender@example.com',
                                               to: 'inbox@example.org',
                                               subject: 'With attachment',
                                               body: 'See attached.',
                                               attachments: [
                                                 { filename: 'report.txt', content: 'attachment-1-content', mime_type: 'text/plain' },
                                                 { filename: 'data.csv', content: "a,b,c\n1,2,3", mime_type: 'text/csv' }
                                               ]
                                             ))
    end

    after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

    let(:fake_container) { instance_double('NfsStore::Manage::Container', id: 4242, master_id: 0) }

    before do
      # Stub container resolution and file import
      allow_any_instance_of(SaveTriggers::PullEmails)
        .to receive(:resolve_attachment_container).and_return(fake_container)
      allow_any_instance_of(SaveTriggers::PullEmails)
        .to receive(:resolve_attachment_user).and_return(@user)

      @imports = []
      stub_stored_file_class = Struct.new(:id, :file_name, :content_type, :file_size)
      allow(NfsStore::Import).to receive(:import_file) do |container_id, file_name, file_path, _user, **opts|
        content = File.read(file_path)
        @imports << { container_id:, file_name:, content:, opts: }
        stub_stored_file_class.new(@imports.length, file_name, opts[:content_type], content.bytesize)
      end
    end

    it 'imports each MIME attachment via NfsStore::Import.import_file' do
      config = {
        source: { type: 'filesystem', path: tmpdir },
        attachments: {
          container: { id: 4242 },
          path: 'emails'
        }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(@imports.length).to eq 2
      expect(@imports.map { |i| i[:file_name] }).to contain_exactly('report.txt', 'data.csv')
      expect(@imports.find { |i| i[:file_name] == 'report.txt' }[:content]).to eq 'attachment-1-content'
      expect(@imports.first[:opts][:path]).to eq 'emails'
    end

    it 'records each captured attachment in trigger_variables[:email][:attachments]' do
      seen = []
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
        seen << trigger.instance_variable_get(:@item).trigger_variables[:email][:attachments].dup
      end

      config = {
        source: { type: 'filesystem', path: tmpdir },
        attachments: { container: { id: 4242 } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(seen.length).to eq 1
      attachments = seen.first
      expect(attachments.length).to eq 2
      expect(attachments.map { |a| a[:filename] }).to contain_exactly('report.txt', 'data.csv')
      report = attachments.find { |a| a[:filename] == 'report.txt' }
      expect(report[:stored_file_id]).to be_present
      expect(report[:content_type]).to start_with('text/plain')
      expect(report[:size]).to eq 'attachment-1-content'.bytesize
    end

    it 'exposes attachments via {{variables.email.attachments.0.stored_file_id}}' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = {
        source: { type: 'filesystem', path: tmpdir },
        attachments: { container: { id: 4242 } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      result = Formatter::Substitution.substitute(
        '{{variables.email.attachments.0.filename}}',
        data: @al, ignore_missing: true
      )
      expect(%w[report.txt data.csv]).to include(result)
    end

    it 'records attachments on the accumulator variables.emails too' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = {
        source: { type: 'filesystem', path: tmpdir },
        attachments: { container: { id: 4242 } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      emails = @al.trigger_variables[:emails]
      expect(emails.first[:attachments].length).to eq 2
    end

    it 'leaves trigger_variables[:email][:attachments] as an empty array when no attachments configured' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      config = { source: { type: 'filesystem', path: tmpdir } }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(@imports).to be_empty
      expect(@al.trigger_variables[:email][:attachments]).to eq []
    end
  end

  describe 'config substitution via FieldDefaults' do
    # Issue #1109: configuration values should be passed through
    # FieldDefaults.calculate_default so secrets, paths, hostnames, bucket
    # names, etc. can be supplied via {{variables.*}} substitutions
    # populated by an earlier set_variables save trigger (or similar).

    let(:tmp_dir) { Dir.mktmpdir(['pull_emails_subst_src', '']) }
    let(:processed_dir) { Dir.mktmpdir(['pull_emails_subst_dst', '']) }

    before do
      File.write(File.join(tmp_dir, 'msg1.eml'), @email1)
      @al.trigger_variables = {
        secrets: {
          inbox_path: tmp_dir,
          processed_path: processed_dir
        },
        config: {
          email_limit: 5
        }
      }
    end

    after do
      FileUtils.remove_entry(tmp_dir) if Dir.exist?(tmp_dir)
      FileUtils.remove_entry(processed_dir) if Dir.exist?(processed_dir)
    end

    it 'resolves {{variables.*}} in source.path, after_processing.move_to.path and limit' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers)

      config = {
        source: { type: 'filesystem', path: '{{variables.secrets.inbox_path}}' },
        limit: '{{variables.config.email_limit}}',
        after_processing: { move_to: { path: '{{variables.secrets.processed_path}}' } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(File.exist?(File.join(tmp_dir, 'msg1.eml'))).to be false
      expect(File.exist?(File.join(processed_dir, 'msg1.eml'))).to be true
    end

    it 'resolves {{variables.*}} in S3 source bucket, prefix and after_processing.move_to.bucket/prefix' do
      stub_client = Aws::S3::Client.new(stub_responses: true, region: 'us-east-1')
      stub_client.stub_responses(:list_objects_v2,
                                 contents: [{ key: 'inbox/email1.eml' }])
      stub_client.stub_responses(:get_object, { body: @email1 })
      copies = []
      deletes = []
      stub_client.stub_responses(:copy_object, lambda { |ctx|
        copies << ctx.params
        { copy_object_result: { etag: '"x"', last_modified: Time.now } }
      })
      stub_client.stub_responses(:delete_object, lambda { |ctx|
        deletes << ctx.params
        {}
      })
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:aws_s3_client).and_return(stub_client)
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers)

      @al.trigger_variables = {
        secrets: { src_bucket: 'src-b', dst_bucket: 'dst-b' },
        config: { src_prefix: 'inbox/', dst_prefix: 'archive/' }
      }
      config = {
        source: {
          type: 's3',
          bucket: '{{variables.secrets.src_bucket}}',
          prefix: '{{variables.config.src_prefix}}'
        },
        after_processing: {
          move_to: {
            bucket: '{{variables.secrets.dst_bucket}}',
            prefix: '{{variables.config.dst_prefix}}'
          }
        }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(copies.first[:bucket]).to eq 'dst-b'
      expect(copies.first[:key]).to eq 'archive/email1.eml'
      expect(copies.first[:copy_source]).to eq 'src-b/inbox/email1.eml'
      expect(deletes.first[:bucket]).to eq 'src-b'
    end

    it 'resolves {{variables.*}} in IMAP source host, username, password and mailbox' do
      fake_imap = instance_double(Net::IMAP)
      allow(Net::IMAP).to receive(:new).and_return(fake_imap)
      allow(fake_imap).to receive(:login)
      allow(fake_imap).to receive(:select)
      allow(fake_imap).to receive(:uid_search).and_return([])
      allow(fake_imap).to receive(:logout)
      allow(fake_imap).to receive(:disconnect)

      @al.trigger_variables = {
        secrets: {
          imap_host: 'imap.internal.example.org',
          imap_user: 'svc-user',
          imap_pass: 's3cret!'
        },
        config: { mailbox: 'Inbox' }
      }
      config = {
        source: {
          type: 'imap',
          host: '{{variables.secrets.imap_host}}',
          username: '{{variables.secrets.imap_user}}',
          password: '{{variables.secrets.imap_pass}}',
          mailbox: '{{variables.config.mailbox}}'
        }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(Net::IMAP).to have_received(:new).with('imap.internal.example.org', port: 143, ssl: nil)
      expect(fake_imap).to have_received(:login).with('svc-user', 's3cret!')
      expect(fake_imap).to have_received(:select).with('Inbox')
    end
  end

  describe 'configuration validation' do
    it 'raises when no source is configured' do
      expect do
        SaveTriggers::PullEmails.new({}, @al).perform
      end.to raise_error(FphsException, /source/)
    end

    it 'raises for an unsupported source type' do
      expect do
        SaveTriggers::PullEmails.new({ source: { type: 'pop3' } }, @al).perform
      end.to raise_error(FphsException, /unsupported|not supported/i)
    end
  end

  describe 'IMAP source (live GreenMail server)' do
    # These tests talk to a real GreenMail SMTP+IMAP server that the
    # developer is expected to have running on localhost. If it is not
    # reachable on the configured ports the entire describe block is
    # skipped so the suite is still green in CI environments without it.
    GREENMAIL_HOST = '127.0.0.1'
    GREENMAIL_SMTP_PORT = 3025
    GREENMAIL_IMAP_PORT = 3143
    GREENMAIL_API_PORT = 8080

    def greenmail_reachable?
      require 'socket'
      TCPSocket.open(GREENMAIL_HOST, GREENMAIL_API_PORT) { true }
    rescue StandardError
      false
    end

    def greenmail_purge!
      require 'net/http'
      uri = URI("http://#{GREENMAIL_HOST}:#{GREENMAIL_API_PORT}/api/service/reset")
      Net::HTTP.post(uri, '')
    rescue StandardError
      nil
    end

    def greenmail_create_user(email, login, password)
      require 'net/http'
      uri = URI("http://#{GREENMAIL_HOST}:#{GREENMAIL_API_PORT}/api/user")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = { email:, login:, password: }.to_json
      Net::HTTP.start(uri.host, uri.port) { |h| h.request(req) }
    end

    def smtp_send(from, to, subject, body)
      require 'net/smtp'
      message = <<~MSG
        From: #{from}
        To: #{to}
        Subject: #{subject}
        Date: #{Time.now.rfc2822}

        #{body}
      MSG
      Net::SMTP.start(GREENMAIL_HOST, GREENMAIL_SMTP_PORT) do |smtp|
        smtp.send_message message, from, to
      end
    end

    before do
      skip 'GreenMail server not reachable on localhost' unless greenmail_reachable?
      greenmail_purge!
      greenmail_create_user('imapuser@study.example.org', 'imapuser', 'imappass')
      smtp_send('sender-a@example.com', 'imapuser@study.example.org', 'IMAP test 1', 'body of msg 1')
      smtp_send('sender-b@example.com', 'imapuser@study.example.org', 'IMAP test 2', 'body of msg 2')
    end

    let(:imap_config) do
      {
        type: 'imap',
        host: GREENMAIL_HOST,
        port: GREENMAIL_IMAP_PORT,
        ssl: false,
        username: 'imapuser',
        password: 'imappass',
        mailbox: 'INBOX'
      }
    end

    it 'reads emails over IMAP and exposes parsed fields via trigger_variables' do
      seen = []
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
        seen << trigger.instance_variable_get(:@item).trigger_variables[:email].dup
      end

      SaveTriggers::PullEmails.new({ source: imap_config }, @al).perform

      expect(seen.length).to eq 2
      expect(seen.map { |e| e[:subject] }).to contain_exactly('IMAP test 1', 'IMAP test 2')
      expect(seen.map { |e| e[:from] }).to contain_exactly('sender-a@example.com', 'sender-b@example.com')
    end

    it 'limits the number of emails read from IMAP' do
      processed = []
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
        processed << trigger.instance_variable_get(:@item).trigger_variables[:email][:subject]
      end

      SaveTriggers::PullEmails.new({ source: imap_config, limit: 1 }, @al).perform

      expect(processed.length).to eq 1
    end

    it 'deletes successfully processed messages from the mailbox' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      SaveTriggers::PullEmails.new({
                                     source: imap_config,
                                     after_processing: { delete: true }
                                   }, @al).perform

      # Re-connect and confirm INBOX is now empty
      imap = Net::IMAP.new(GREENMAIL_HOST, port: GREENMAIL_IMAP_PORT, ssl: false)
      imap.login('imapuser', 'imappass')
      imap.select('INBOX')
      uids = imap.search(['ALL'])
      imap.logout
      imap.disconnect
      expect(uids).to be_empty
    end

    it 'moves successfully processed messages to another mailbox' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      SaveTriggers::PullEmails.new({
                                     source: imap_config,
                                     after_processing: { move_to: { mailbox: 'Processed' } }
                                   }, @al).perform

      imap = Net::IMAP.new(GREENMAIL_HOST, port: GREENMAIL_IMAP_PORT, ssl: false)
      imap.login('imapuser', 'imappass')
      imap.select('INBOX')
      inbox_uids = imap.search(['ALL'])
      imap.select('Processed')
      processed_uids = imap.search(['ALL'])
      imap.logout
      imap.disconnect

      expect(inbox_uids).to be_empty
      expect(processed_uids.length).to eq 2
    end

    it 'leaves messages untouched when after_processing is not set' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers).and_return(true)

      SaveTriggers::PullEmails.new({ source: imap_config }, @al).perform

      imap = Net::IMAP.new(GREENMAIL_HOST, port: GREENMAIL_IMAP_PORT, ssl: false)
      imap.login('imapuser', 'imappass')
      imap.select('INBOX')
      uids = imap.search(['ALL'])
      imap.logout
      imap.disconnect

      expect(uids.length).to eq 2
    end

    it 'does not delete a message whose triggers raised' do
      call_count = 0
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do
        call_count += 1
        raise FphsException, 'boom' if call_count == 1

        true
      end

      SaveTriggers::PullEmails.new({
                                     source: imap_config,
                                     after_processing: { delete: true }
                                   }, @al).perform

      imap = Net::IMAP.new(GREENMAIL_HOST, port: GREENMAIL_IMAP_PORT, ssl: false)
      imap.login('imapuser', 'imappass')
      imap.select('INBOX')
      remaining = imap.search(['ALL'])
      imap.logout
      imap.disconnect

      expect(remaining.length).to eq 1
    end
  end

  describe 'per-email status, lifecycle hooks, and attachment failure isolation' do
    # Issue #1109: per-email failures should be visible on the
    # variables.emails accumulator (status/error fields), should not
    # cause the email to be moved/deleted (so it can be retried), and
    # should fire optional on_email_failure hooks. Successful emails
    # should fire on_email_complete hooks. Attachment storage failures
    # should mark the individual attachment as failed AND mark the
    # email as failed so it is retried; with attachments.skip_existing
    # already-stored attachments are not duplicated on retry.

    let(:tmp_dir) { Dir.mktmpdir(['pull_emails_lifecycle_src', '']) }
    let(:processed_dir) { Dir.mktmpdir(['pull_emails_lifecycle_dst', '']) }

    before do
      File.write(File.join(tmp_dir, 'ok.eml'), @email1)
      File.write(File.join(tmp_dir, 'bad.eml'), @email2)
    end

    after do
      FileUtils.remove_entry(tmp_dir) if Dir.exist?(tmp_dir)
      FileUtils.remove_entry(processed_dir) if Dir.exist?(processed_dir)
    end

    it 'records status: ok on the emails accumulator for successfully processed emails' do
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers)
      config = { source: { type: 'filesystem', path: tmp_dir } }
      SaveTriggers::PullEmails.new(config, @al).perform

      statuses = @al.trigger_variables[:emails].map { |e| e[:status] }
      expect(statuses).to all(eq('ok'))
    end

    it "records status: 'failed' and the error message when on_email triggers raise" do
      call_count = 0
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do
        call_count += 1
        raise FphsException, 'boom on second' if call_count == 2
      end
      config = { source: { type: 'filesystem', path: tmp_dir } }
      SaveTriggers::PullEmails.new(config, @al).perform

      emails = @al.trigger_variables[:emails]
      expect(emails.length).to eq 2
      expect(emails[0][:status]).to eq 'ok'
      expect(emails[1][:status]).to eq 'failed'
      expect(emails[1][:error]).to include('boom on second')
    end

    it 'leaves a failed email in place (does not move or delete it)' do
      call_count = 0
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do
        call_count += 1
        raise FphsException, 'boom' if call_count == 2
      end
      config = {
        source: { type: 'filesystem', path: tmp_dir },
        after_processing: { move_to: { path: processed_dir } }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      remaining = Dir.children(tmp_dir).sort
      moved = Dir.children(processed_dir).sort
      # Only the first (ok) email is moved; the second remains in source
      expect(remaining.length).to eq 1
      expect(moved.length).to eq 1
    end

    it 'fires on_email_complete only after a successful email' do
      complete_calls = []
      failure_calls = []

      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers)
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_complete_triggers) do |inst|
        complete_calls << inst.item.trigger_variables[:email][:source_key]
      end
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_failure_triggers) do |inst|
        failure_calls << inst.item.trigger_variables[:email][:source_key]
      end

      config = {
        source: { type: 'filesystem', path: tmp_dir },
        on_email_complete: [{ update_this: { with: { notes: 'ok' } } }],
        on_email_failure: [{ update_this: { with: { notes: 'fail' } } }]
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(complete_calls.length).to eq 2
      expect(failure_calls).to be_empty
    end

    it 'fires on_email_failure only when an email fails, with on_email_complete not fired for it' do
      complete_calls = []
      failure_calls = []
      call_count = 0

      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do
        call_count += 1
        raise FphsException, 'boom' if call_count == 2
      end
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_complete_triggers) do |inst|
        complete_calls << inst.item.trigger_variables[:email][:source_key]
      end
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_failure_triggers) do |inst|
        failure_calls << [inst.item.trigger_variables[:email][:source_key],
                          inst.item.trigger_variables[:email][:status],
                          inst.item.trigger_variables[:email][:error]]
      end

      config = {
        source: { type: 'filesystem', path: tmp_dir },
        on_email_complete: [{ update_this: { with: { notes: 'ok' } } }],
        on_email_failure: [{ update_this: { with: { notes: 'fail' } } }]
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      expect(complete_calls.length).to eq 1
      expect(failure_calls.length).to eq 1
      _src, status, err = failure_calls.first
      expect(status).to eq 'failed'
      expect(err).to include('boom')
    end

    it 'records per-attachment status when an attachment fails to store, marks email as failed, and leaves email in source' do
      with_attachment = build_mime_email(
        from: 'a@example.com', to: 'b@example.com',
        subject: 'has-attachments', body: 'b',
        attachments: [
          { filename: 'good.txt', content: 'good content', mime_type: 'text/plain' },
          { filename: 'bad.txt', content: 'bad content', mime_type: 'text/plain' }
        ]
      )
      attach_dir = Dir.mktmpdir(['pull_emails_attach', ''])
      File.write(File.join(attach_dir, 'msg.eml'), with_attachment)

      fake_container = instance_double(NfsStore::Manage::Container, id: 999, master_id: @master.id)
      allow_any_instance_of(SaveTriggers::PullEmails)
        .to receive(:resolve_attachment_container).and_return(fake_container)
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:resolve_attachment_user).and_return(@user)
      allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers)

      stored_file = double('StoredFile', id: 7777)
      allow(NfsStore::Import).to receive(:import_file) do |_, filename, _, _, **_|
        raise StandardError, 'disk full' if filename == 'bad.txt'

        stored_file
      end

      config = {
        source: { type: 'filesystem', path: attach_dir },
        attachments: { container: { id: 999 }, path: 'emails' },
        after_processing: { delete: true }
      }
      SaveTriggers::PullEmails.new(config, @al).perform

      email = @al.trigger_variables[:emails].first
      attachments = email[:attachments]
      good = attachments.find { |a| a[:filename] == 'good.txt' }
      bad  = attachments.find { |a| a[:filename] == 'bad.txt' }
      expect(good[:status]).to eq 'ok'
      expect(good[:stored_file_id]).to eq 7777
      expect(bad[:status]).to eq 'failed'
      expect(bad[:error]).to include('disk full')

      # The email itself is marked failed and is not deleted, so it can be retried
      expect(email[:status]).to eq 'failed'
      expect(File.exist?(File.join(attach_dir, 'msg.eml'))).to be true
    ensure
      FileUtils.remove_entry(attach_dir) if attach_dir && Dir.exist?(attach_dir)
    end
  end

  describe 'incremental retrieval (since_uid / since_modified)' do
    # Issue #1109 follow-up: allow callers to skip already-processed
    # messages by specifying:
    #   - source.since_uid       (IMAP) - only UIDs strictly greater than this
    #   - source.since_modified  (S3 / filesystem) - only objects whose
    #                              last-modified time is strictly newer
    # Both values are passed through FieldDefaults so they may be supplied
    # via {{variables.*}} (typically the value from the previous run).

    describe 'S3 source' do
      let(:bucket) { 'inc-bucket' }
      let(:prefix) { 'inbox/' }
      let(:t_old) { Time.utc(2026, 5, 1, 10, 0, 0) }
      let(:t_new) { Time.utc(2026, 5, 1, 12, 0, 0) }
      let(:cutoff) { Time.utc(2026, 5, 1, 11, 0, 0) }

      let(:stub_client) do
        Aws::S3::Client.new(stub_responses: true, region: 'us-east-1')
      end

      before do
        stub_client.stub_responses(:list_objects_v2,
                                   contents: [
                                     { key: "#{prefix}old.eml", last_modified: t_old },
                                     { key: "#{prefix}new.eml", last_modified: t_new }
                                   ])
        stub_client.stub_responses(:get_object, lambda { |ctx|
          case ctx.params[:key]
          when "#{prefix}old.eml" then { body: @email1 }
          when "#{prefix}new.eml" then { body: @email2 }
          else { body: '' }
          end
        })
        allow_any_instance_of(SaveTriggers::PullEmails)
          .to receive(:aws_s3_client).and_return(stub_client)
      end

      it 'skips S3 objects whose last_modified is not strictly newer than since_modified' do
        seen = []
        allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
          seen << trigger.instance_variable_get(:@item).trigger_variables[:email][:source_key]
        end
        config = {
          source: { type: 's3', bucket:, prefix:, since_modified: cutoff.iso8601 }
        }
        SaveTriggers::PullEmails.new(config, @al).perform

        expect(seen).to eq ["#{prefix}new.eml"]
      end

      it 'resolves {{variables.*}} in source.since_modified' do
        @al.trigger_variables = { last_run: { at: cutoff.iso8601 } }
        seen = []
        allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
          seen << trigger.instance_variable_get(:@item).trigger_variables[:email][:source_key]
        end
        config = {
          source: {
            type: 's3', bucket:, prefix:,
            since_modified: '{{variables.last_run.at}}'
          }
        }
        SaveTriggers::PullEmails.new(config, @al).perform

        expect(seen).to eq ["#{prefix}new.eml"]
      end
    end

    describe 'filesystem source' do
      let(:tmp_dir) { Dir.mktmpdir(['pull_emails_inc', '']) }
      let(:cutoff) { Time.now }

      before do
        @old_path = File.join(tmp_dir, 'old.eml')
        @new_path = File.join(tmp_dir, 'new.eml')
        File.write(@old_path, @email1)
        File.write(@new_path, @email2)
        FileUtils.touch(@old_path, mtime: cutoff - 3600)
        FileUtils.touch(@new_path, mtime: cutoff + 3600)
      end

      after { FileUtils.remove_entry(tmp_dir) if Dir.exist?(tmp_dir) }

      it 'skips files whose mtime is not strictly newer than since_modified' do
        seen = []
        allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers) do |trigger|
          seen << trigger.instance_variable_get(:@item).trigger_variables[:email][:source_key]
        end
        config = {
          source: { type: 'filesystem', path: tmp_dir, since_modified: cutoff.iso8601 }
        }
        SaveTriggers::PullEmails.new(config, @al).perform

        expect(seen).to eq [@new_path]
      end
    end

    describe 'IMAP source (mocked)' do
      it 'restricts uid_search to UIDs strictly greater than since_uid' do
        fake_imap = instance_double(Net::IMAP)
        allow(Net::IMAP).to receive(:new).and_return(fake_imap)
        allow(fake_imap).to receive(:login)
        allow(fake_imap).to receive(:select)
        allow(fake_imap).to receive(:logout)
        allow(fake_imap).to receive(:disconnect)
        allow(fake_imap).to receive(:uid_search).and_return([100, 101, 105])
        allow(fake_imap).to receive(:uid_fetch) do |uid, _|
          [double('FetchData', attr: { 'RFC822' => @email1 }, seqno: uid)]
        end

        config = {
          source: {
            type: 'imap', host: 'h', username: 'u', password: 'p',
            since_uid: 100
          }
        }
        allow_any_instance_of(SaveTriggers::PullEmails).to receive(:run_on_email_triggers)
        SaveTriggers::PullEmails.new(config, @al).perform

        # IMAP uses inclusive ranges, so a 101:* search returns >= 101
        # i.e. strictly greater than since_uid
        expect(fake_imap).to have_received(:uid_search).with(['UID', '101:*'])
      end

      it 'resolves {{variables.*}} in source.since_uid' do
        fake_imap = instance_double(Net::IMAP)
        allow(Net::IMAP).to receive(:new).and_return(fake_imap)
        allow(fake_imap).to receive(:login)
        allow(fake_imap).to receive(:select)
        allow(fake_imap).to receive(:logout)
        allow(fake_imap).to receive(:disconnect)
        allow(fake_imap).to receive(:uid_search).and_return([])

        @al.trigger_variables = { last_run: { uid: '42' } }
        config = {
          source: {
            type: 'imap', host: 'h', username: 'u', password: 'p',
            since_uid: '{{variables.last_run.uid}}'
          }
        }
        SaveTriggers::PullEmails.new(config, @al).perform

        expect(fake_imap).to have_received(:uid_search).with(['UID', '43:*'])
      end
    end
  end

  describe 'registration' do
    it 'is registered as a valid save trigger' do
      expect(OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers)
        .to include(:pull_emails)
    end
  end
end
