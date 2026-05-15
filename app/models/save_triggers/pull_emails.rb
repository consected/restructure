# frozen_string_literal: true

#
# Save trigger that reads MIME-encoded email files (for example, those
# captured by AWS SES and stored in an S3 bucket) and runs a list of
# inner save triggers per email.
#
# For each email, the parsed fields (from, to, cc, bcc, subject, body,
# headers, raw, source_key) are exposed via the item's
# trigger_variables[:email] hash, and so are available to the inner
# triggers (and any substitutions within them) using
# `{{variables.email.subject}}`, etc.
#
# After successful processing of an email, the source file may be moved
# to another location or deleted, so it is not processed twice.
#
# Configuration:
#
#   pull_emails:
#     source:
#       type: s3                # or 'filesystem'
#       bucket: my-bucket
#       prefix: 'inbox/'
#       # filesystem source uses:
#       # path: /var/mail/incoming
#     limit: 50                 # optional cap on emails processed
#     after_processing:
#       move_to:
#         prefix: 'processed/'  # for s3
#         # path: /var/mail/processed  # for filesystem
#         bucket: alt-bucket    # optional, defaults to source bucket
#       delete: true            # alternative to move_to
#     on_email:
#       - create_reference:
#           ...
#       - update_this:
#           with:
#             notes: '{{variables.email.subject}}'
#
# See GitHub issue consected/restructure#1109.
require 'net/imap'

class SaveTriggers::PullEmails < SaveTriggers::SaveTriggersBase
  SUPPORTED_SOURCE_TYPES = %w[s3 filesystem imap].freeze

  def initialize(config, item)
    super
    @config = config.is_a?(Hash) ? config : {}
  end

  def perform
    source = resolved_source
    raise FphsException, 'pull_emails requires a source configuration' if source.blank?

    type = source[:type].to_s
    unless SUPPORTED_SOURCE_TYPES.include?(type)
      raise FphsException, "pull_emails source type '#{type}' is not supported"
    end

    after_cfg = resolved_after_processing
    processed = 0
    iterate_source(source) do |email_id, raw_content|
      break if limit && processed >= limit

      mail = parse_mime(raw_content)
      assign_email_trigger_variables(mail, raw_content, email_id)
      capture_attachments(mail) if resolved_attachments.present? && step_applies?(resolved_attachments)

      attachment_failed = current_email[:status] == 'failed'

      begin
        run_on_email_triggers
      rescue FphsException => e
        Rails.logger.warn "pull_emails: trigger failed for #{email_id}: #{e.message}"
        mark_current_email_failed(e.message)
      end

      processed += 1
      success = current_email[:status] != 'failed'
      if success
        run_on_email_complete_triggers
        after_process(source, after_cfg, email_id) if step_applies?(after_cfg)
      else
        # Re-mark failed in case attachment failed but on_email succeeded -
        # ensure we never move/delete a partially-failed email.
        mark_current_email_failed(current_email[:error] || 'attachment storage failed') if attachment_failed
        run_on_email_failure_triggers
      end
    end

    processed
  end

  # Run the configured per-email triggers.
  # Extracted so specs can stub the iteration without performing real
  # save trigger side-effects.
  def run_on_email_triggers
    triggers = @config[:on_email]
    return if triggers.blank?

    execute_trigger_list(triggers)
  end

  # Per-email lifecycle hooks. on_email_complete fires only when the
  # main on_email triggers (and any attachment storage) succeeded for
  # this individual email. on_email_failure fires only when the email
  # was marked as failed. Within these hooks {{variables.email.*}} is
  # the current email (with status/error fields populated).
  def run_on_email_complete_triggers
    triggers = @config[:on_email_complete]
    return if triggers.blank?

    execute_trigger_list(triggers)
  end

  def run_on_email_failure_triggers
    triggers = @config[:on_email_failure]
    return if triggers.blank?

    begin
      execute_trigger_list(triggers)
    rescue StandardError => e
      Rails.logger.error "pull_emails: on_email_failure trigger itself raised: #{e.message}"
    end
  end

  # AWS S3 client - extracted so it is easy to override / mock.
  def aws_s3_client
    @aws_s3_client ||= Aws::S3::Client.new(region: AwsApiSetup.s3_aws_region)
  end

  private

  # Returns true when the step should run: either no +if:+ condition is
  # present in +cfg+, or the condition evaluates as truthy.
  def step_applies?(cfg)
    return true if cfg.blank?

    if_cond = cfg[:if]
    if_cond.blank? || if_evaluates(if_cond)
  end

  # Resolve {{variables.*}} (and other FieldDefaults patterns) within the
  # source configuration so that hostnames, bucket names, paths, usernames,
  # passwords, etc. can be supplied dynamically (e.g. populated by an
  # earlier set_variables save trigger from secret config).
  def resolved_source
    src = @config[:source]
    return src unless src.is_a?(Hash)

    @resolved_source ||= FieldDefaults.substitute_value_recurse(
      @item, src, allow_nil: true, ignore_missing: true
    )
  end

  def resolved_after_processing
    after = @config[:after_processing]
    return after unless after.is_a?(Hash)

    @resolved_after_processing ||= FieldDefaults.substitute_value_recurse(
      @item, after, allow_nil: true, ignore_missing: true
    )
  end

  def resolved_attachments
    attachments = @config[:attachments]
    return attachments unless attachments.is_a?(Hash)

    @resolved_attachments ||= FieldDefaults.substitute_value_recurse(
      @item, attachments, allow_nil: true, ignore_missing: true
    )
  end

  def limit
    raw = @config[:limit]
    return nil if raw.nil?

    val = FieldDefaults.calculate_default(@item, raw, allow_nil: true, ignore_missing: true)
    val.to_s.empty? ? nil : val.to_i
  end

  def iterate_source(source, &)
    case source[:type].to_s
    when 's3'
      iterate_s3(source, &)
    when 'filesystem'
      iterate_filesystem(source, &)
    when 'imap'
      iterate_imap(source, &)
    end
  end

  def iterate_s3(source)
    bucket = source[:bucket]
    raise FphsException, 'pull_emails s3 source requires bucket' if bucket.blank?

    prefix = source[:prefix]
    cutoff = parse_since_modified(source[:since_modified])
    list_params = { bucket: }
    list_params[:prefix] = prefix if prefix.present?
    res = aws_s3_client.list_objects_v2(list_params)

    contents = res.contents || []
    contents.each do |obj|
      key = obj.respond_to?(:key) ? obj.key : obj[:key]
      # Skip "directory" placeholders (S3 doesn't really have folders, but
      # zero-byte keys ending in '/' are commonly used to fake them)
      next if key.end_with?('/')

      if cutoff
        last_modified = obj.respond_to?(:last_modified) ? obj.last_modified : obj[:last_modified]
        next unless last_modified && last_modified.to_time > cutoff
      end

      raw = aws_s3_client.get_object(bucket:, key:).body.read
      yield key, raw
    end
  end

  def iterate_filesystem(source)
    path = source[:path]
    raise FphsException, 'pull_emails filesystem source requires path' if path.blank?
    raise FphsException, "pull_emails filesystem path does not exist: #{path}" unless File.directory?(path)

    cutoff = parse_since_modified(source[:since_modified])

    entries = Dir.children(path).map { |e| File.join(path, e) }.select { |f| File.file?(f) }
    entries = entries.select { |f| File.mtime(f) > cutoff } if cutoff
    # Process in mtime order so newest comes last - this gives the
    # accumulator a natural "oldest first" ordering matching the cutoff.
    entries.sort_by { |f| File.mtime(f) }.each do |full|
      raw = File.read(full)
      yield full, raw
    end
  end

  # Parse a since_modified value (Time, DateTime, or ISO8601 string) to a Time.
  # Returns nil if the value is blank or unparseable.
  def parse_since_modified(value)
    return nil if value.blank?
    return value.to_time if value.respond_to?(:to_time) && !value.is_a?(String)

    Time.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def parse_mime(raw_content)
    Mail.read_from_string(raw_content)
  rescue StandardError => e
    raise FphsException, "pull_emails failed to parse MIME content: #{e.message}"
  end

  def assign_email_trigger_variables(mail, raw_content, source_key)
    @item.trigger_variables ||= {} if @item.respond_to?(:trigger_variables)
    return unless @item.respond_to?(:trigger_variables)

    email_hash = {
      from: array_or_first(mail.from),
      to: Array(mail.to),
      cc: Array(mail.cc),
      bcc: Array(mail.bcc),
      subject: mail.subject.to_s,
      body: extract_body(mail),
      headers: extract_headers(mail),
      source_key:,
      raw: raw_content,
      attachments: [],
      status: 'ok',
      error: nil
    }

    # Current email accessible as {{variables.email.subject}}
    @item.trigger_variables[:email] = email_hash

    # Accumulated list of all processed emails accessible as
    # {{variables.emails.0.subject}}, {{variables.emails.1.from}}, etc.
    @item.trigger_variables[:emails] ||= []
    @item.trigger_variables[:emails] << email_hash
  end

  # Returns the currently active email hash on the item's trigger_variables
  # (the same object that lives on both [:email] and the tail of [:emails]).
  def current_email
    @item.trigger_variables[:email] || {}
  end

  # Mark the current email as failed and copy the failure onto the
  # corresponding entry in the variables.emails accumulator (they refer
  # to the same hash, so a single mutation updates both).
  def mark_current_email_failed(message)
    return unless @item.trigger_variables[:email]

    @item.trigger_variables[:email][:status] = 'failed'
    @item.trigger_variables[:email][:error] = message.to_s
  end

  def array_or_first(value)
    arr = Array(value)
    arr.length == 1 ? arr.first : arr
  end

  def extract_body(mail)
    if mail.multipart?
      text_part = mail.text_part || mail.html_part
      text_part&.decoded.to_s
    else
      mail.body.decoded.to_s
    end
  end

  def extract_headers(mail)
    headers = {}
    mail.header.fields.each do |f|
      headers[f.name] = f.value.to_s
    end
    headers
  end

  def after_process(source, after, source_key)
    return if after.blank?

    case source[:type].to_s
    when 's3'
      after_process_s3(source, source_key, after)
    when 'imap'
      after_process_imap(source_key, after)
    else
      after_process_filesystem(source_key, after)
    end
  end

  def after_process_s3(source, source_key, after)
    bucket = source[:bucket]
    move_to = after[:move_to]
    if move_to.present?
      target_bucket = move_to[:bucket] || bucket
      target_prefix = move_to[:prefix].to_s
      filename = File.basename(source_key)
      target_key = "#{target_prefix}#{filename}"
      aws_s3_client.copy_object(
        bucket: target_bucket,
        key: target_key,
        copy_source: "#{bucket}/#{source_key}"
      )
      aws_s3_client.delete_object(bucket:, key: source_key)
    elsif after[:delete]
      aws_s3_client.delete_object(bucket:, key: source_key)
    end
  end

  def after_process_filesystem(source_path, after)
    move_to = after[:move_to]
    if move_to.present? && move_to[:path].present?
      FileUtils.mkdir_p(move_to[:path])
      FileUtils.mv(source_path, File.join(move_to[:path], File.basename(source_path)))
    elsif after[:delete]
      File.delete(source_path) if File.file?(source_path)
    end
  end

  # IMAP source. Connects, selects the source mailbox, optionally runs
  # an IMAP search (default ALL), fetches RFC822 bodies and yields each
  # one. The connection is held open until iteration completes so that
  # any after_processing operations targeting the same UID work without
  # re-opening the session.
  # The yielded "email_id" is the IMAP UID (Integer) so after_process
  # can act on it.
  def iterate_imap(source)
    raise FphsException, 'pull_emails imap source requires host' if source[:host].blank?
    raise FphsException, 'pull_emails imap source requires username' if source[:username].blank?

    imap_open(source)
    @imap_mailbox = source[:mailbox] || 'INBOX'
    @imap.select(@imap_mailbox)

    search_criteria = build_imap_search_criteria(source)
    uids = @imap.uid_search(search_criteria) || []

    uids.each do |uid|
      data = @imap.uid_fetch(uid, ['RFC822'])
      next if data.blank?

      raw = data.first.attr['RFC822']
      yield uid, raw
    end
  ensure
    imap_close
  end

  # Build the IMAP search criteria. Honors source.search (explicit IMAP
  # search args, or a single string) and source.since_uid (only return
  # UIDs strictly greater than the supplied value, e.g. the value
  # captured from a previous run). When both are given, since_uid is
  # appended to the search criteria.
  def build_imap_search_criteria(source)
    base = source[:search] || ['ALL']
    base = [base] if base.is_a?(String)

    since_uid = source[:since_uid]
    return base if since_uid.blank?

    next_uid = since_uid.to_i + 1
    uid_clause = ['UID', "#{next_uid}:*"]
    return uid_clause if base == ['ALL']

    base + uid_clause
  end

  def imap_open(source)
    port = source[:port] || (source[:ssl] ? 993 : 143)
    @imap = Net::IMAP.new(source[:host], port:, ssl: source[:ssl])
    @imap.login(source[:username], source[:password])
  end

  def imap_close
    @imap&.logout
  rescue StandardError
    nil
  ensure
    begin
      @imap&.disconnect
    rescue StandardError
      nil
    end
    @imap = nil
  end

  def after_process_imap(uid, after)
    move_to = after[:move_to]
    if move_to.present? && move_to[:mailbox].present?
      target = move_to[:mailbox]
      ensure_imap_mailbox(target)
      @imap.uid_copy(uid, target)
      @imap.uid_store(uid, '+FLAGS', [:Deleted])
      @imap.expunge
    elsif after[:delete]
      @imap.uid_store(uid, '+FLAGS', [:Deleted])
      @imap.expunge
    end
  end

  def ensure_imap_mailbox(name)
    @imap.create(name)
  rescue Net::IMAP::NoResponseError
    # mailbox already exists
  end

  #
  # Save each MIME attachment from the parsed email into the configured
  # NfsStore container, recording metadata under
  # trigger_variables[:email][:attachments] (and the matching entry on the
  # accumulator trigger_variables[:emails]).
  # Mirrors the file-storage approach used by SaveTriggers::GenerateDocument.
  # @param [Mail::Message] mail
  def capture_attachments(mail)
    attachments_config = resolved_attachments
    return if attachments_config.blank?
    return if mail.attachments.blank?

    container = resolve_attachment_container(attachments_config)
    store_user = resolve_attachment_user(attachments_config)
    path = FieldDefaults.calculate_default(@item, attachments_config[:path],
                                           allow_nil: true, ignore_missing: true)
    skip_existing = attachments_config[:skip_existing]
    replace = attachments_config[:replace]

    captured = []
    any_failed = false
    last_error = nil
    mail.attachments.each do |attachment|
      info = store_single_attachment(attachment, container, store_user,
                                     path:, skip_existing:, replace:)
      next unless info

      captured << info
      if info[:status] == 'failed'
        any_failed = true
        last_error = info[:error]
      end
    end

    @item.trigger_variables[:email][:attachments] = captured
    @item.trigger_variables[:emails].last[:attachments] = captured if @item.trigger_variables[:emails]
    mark_current_email_failed("attachment storage failed: #{last_error}") if any_failed
  end

  def store_single_attachment(attachment, container, store_user, path:, skip_existing:, replace:)
    filename = sanitize_filename(attachment.filename.to_s)
    return nil if filename.blank?

    body = attachment.decoded
    temp_file = Tempfile.new(['pull_emails_attach', File.extname(filename)])
    temp_file.binmode
    temp_file.write(body)
    temp_file.close

    stored_file = NfsStore::Import.import_file(
      container.id,
      filename,
      temp_file.path,
      store_user,
      path:,
      skip_existing:,
      replace:
    )

    {
      filename:,
      content_type: attachment.content_type.to_s,
      size: body.bytesize,
      stored_file_id: stored_file&.id,
      stored_file:,
      status: 'ok',
      error: nil
    }
  rescue StandardError => e
    Rails.logger.warn "pull_emails: failed to store attachment #{filename}: #{e.message}"
    {
      filename:,
      content_type: attachment.content_type.to_s,
      size: body&.bytesize,
      stored_file_id: nil,
      stored_file: nil,
      status: 'failed',
      error: e.message
    }
  ensure
    temp_file&.close
    temp_file&.unlink
  end

  # Resolve the target NFS container from the attachments.container config.
  # Mirrors SaveTriggers::GenerateDocument#resolve_container, accepting:
  #   - from_this: model_reference
  #   - id: <container id>
  #   - name: <container name>
  def resolve_attachment_container(attachments_config)
    container_config = attachments_config[:container]
    raise FphsException, 'pull_emails attachments requires container configuration' unless container_config.is_a?(Hash)

    container =
      if container_config[:from_this] == 'model_reference'
        refs = ModelReference.find_references(@item, to_record_type: 'nfs_store__manage__container', active: true)
        refs.first&.to_record
      elsif container_config[:id]
        cid = FieldDefaults.calculate_default(@item, container_config[:id], allow_nil: true, ignore_missing: true)
        NfsStore::Manage::Container.find_by(id: cid)
      elsif container_config[:name]
        cname = FieldDefaults.calculate_default(@item, container_config[:name], allow_nil: true,
                                                                                ignore_missing: true)
        NfsStore::Manage::Container.where(master_id: @item.master_id, name: cname).first
      end

    raise FphsException, "pull_emails could not resolve attachment container: #{container_config}" unless container

    container
  end

  # Resolve the user for the file store import. Falls back to @user.
  def resolve_attachment_user(attachments_config)
    user_config = {
      user: FieldDefaults.calculate_default(@item, attachments_config[:store_as_user],
                                            allow_nil: true, ignore_missing: true),
      app_type: FieldDefaults.calculate_default(@item, attachments_config[:store_in_app_type],
                                                allow_nil: true, ignore_missing: true)
    }.compact

    if user_config.present?
      resolved = DynamicModel.user_for_conf_snippet(user_config)
      return resolved if resolved
    end

    @user
  end

  # Sanitize a filename to prevent path traversal. Matches the approach
  # used by SaveTriggers::GenerateDocument#sanitize_filename.
  def sanitize_filename(filename)
    filename = filename.gsub('..', '')
    filename = filename.gsub(%r{[/\\]}, '')
    filename.strip.gsub(/\A\.+|\.+\z/, '')
  end
end
