#!/usr/bin/env ruby

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end

require 'net/http'
require 'mime/types'
require 'uri'
require 'json'
require 'active_support/core_ext/hash/keys'
require 'fileutils'

DryRun = !ENV['DRY_RUN'].nil?
CompareDates = false

Debug = false

SkipSlugs = ['example-layouts']
LimitToSections = ENV['SECTIONS']&.split(',')

# continue rather than exiting on an error
ErrorContinue = true
DefaultMimeType = 'application/octet-stream'.freeze

puts 'DRY RUN!' if DryRun

def source
  {
    username: ENV['SRC_API_USER'],
    token: ENV['SRC_API_TOKEN'],
    app_type: 16,
    protocol: 'https',
    host: ENV['SRC_HOST'],
    port: '443'
  }
end

def dest
  {
    username: ENV['DEST_API_USER'],
    token: ENV['DEST_API_TOKEN'],
    app_type: 16,
    protocol: 'https',
    host: ENV['DEST_HOST'],
    port: '443'
  }
end

delete_atts = %w[id created_at created_at_ts updated_at updated_at_ts user_id created_by_user_email created_by_user_name
                 creatable_model_references def_version embedded_item embedded_items human_name ids item_type
                 master_created_by_user master_created_by_user_email master_id model_data_type model_references
                 prevent_add_reference prevent_edit rank_name referenced_from resource_name source_name update_action
                 user_email user_id user_name user_preference vdef_version _created _general_selections _updated]

part_attribs = %w[extra_log_type title description default_layout slug tag_select_allow_roles_access footer tag_select_page_tags
                  position_number extra_classes notes]

ContainerListAttribs = %w[file_name file_size path title].freeze
FileTitleAttribs = %w[title description].freeze

failures = []

DummyResponse = Struct.new(:code, :body) do
  def body
    '{}'
  end
end

def build_uri(target, path:, query: nil)
  query = URI.encode_www_form(query) if query
  path = path.gsub(' ', '%20')
  uri_class = URI.const_get target[:protocol].upcase
  uri_class.build(host: target[:host], port: target[:port], path: path, query: query)
end

def query_merge_auth!(query, target)
  query.merge!(
    user_email: target[:username],
    user_token: target[:token],
    use_app_type: target[:app_type]
  )
end

def get(target, path, query = {})
  query = query.merge(
    user_email: target[:username],
    user_token: target[:token],
    use_app_type: target[:app_type]
  )

  uri = build_uri(target, path: path, query: query)
  Net::HTTP.get_response(uri)
end

def post(target, path, query = {}, form = {})
  return DummyResponse.new('200') if DryRun

  query = query.merge(
    user_email: target[:username],
    user_token: target[:token],
    use_app_type: target[:app_type]
  )

  uri = build_uri(target, path: path, query: query)
  res = Net::HTTP.post_form(uri, form)
  puts_debug res.body
  res
end

def patch(target, path, query = {}, form = {})
  form['_method'] = 'patch'
  post target, path, query, form
end

def fix_form(form, to_type)
  form_prefix = to_type.gsub('__', '_')

  form.transform_keys! { |k| "#{form_prefix}[#{k}]" }

  # Array fields need to be split into appropriate parameters
  array_fields = {}
  fixed_array_fields = []
  form.each do |k, v|
    if k.include?('tag_select_') && v.nil?
      array_fields["#{k}[]"] = ''
      fixed_array_fields << k
      next
    elsif !v.is_a?(Array)
      next
    end

    fixed_array_fields << k
    item_num = -1

    array_fields.merge!("#{k}[]" => v)
  end

  # Remove the original entries for array fields
  fixed_array_fields.each do |k|
    form.delete k
  end

  # Add in the new multiple entries for each array field
  form.merge! array_fields
end

def path_prefix(master_id)
  path_pre = ''
  path_pre = "/masters/#{master_id}" if master_id
  path_pre
end

def get_target_record(target, to_type, type_path, id, master_id, query: {})
  path = "#{path_prefix(master_id)}/#{type_path}/#{id}.json"

  response = get target, path, query
  if response.code != '200'
    puts_error "failed to get referenced to record on #{target[:host]}: #{response.code} - #{path} "
    return
  end
  dest_record_res = JSON.parse(response.body)
  dest_record = dest_record_res[to_type]
end

def get_container_list(target, activity_log_id, activity_log_type, container_id)
  path = "/nfs_store/container_list/#{container_id}/content"
  query = { activity_log_id: activity_log_id, activity_log_type: activity_log_type }
  response = get target, path, query
  if response.code != '200'
    puts_error "failed to get container list on #{target[:host]}: #{response.code} - #{path} ? #{query}"
    return
  end
  res = JSON.parse(response.body)
  res['nfs_store_container']
end

def send_files_to_trash(to_disable, dest_al_id, dest_container_id)
  to_disable = to_disable.map(&:to_json)
  form = {
    'nfs_store_download[selected_items][]' => to_disable,
    'nfs_store_download[activity_log_type]' => 'activity_log__study_info_part',
    'nfs_store_download[activity_log_id]' => dest_al_id,
    'nfs_store_download[container_id]' => dest_container_id,
    'commit' => 'Trash'
  }
  path = '/nfs_store/downloads'
  query = {}
  response = post(dest, path, query, form)
  if response.code != '200'
    puts_error "failed to trash files in destination: #{response.code} - #{path}\n#{form}\n#{response.body}"
  else
    puts_success "successfully trashed unused files in destination container (#{dest_container_id}): #{to_disable}"
  end
  response
end

def download_file(download_id, filename, source_al_id, source_container_id)
  get_query = {
    retrieval_type: 'stored_file',
    download_id: download_id,
    activity_log_id: source_al_id,
    activity_log_type: 'activity_log__study_info_part'
  }

  query_merge_auth!(get_query, source)
  url = build_uri(source, path: "/nfs_store/downloads/#{source_container_id}", query: get_query)
  upload_dir_path = '/tmp/tx-instance-temp-dir'
  upload_file_path = "#{upload_dir_path}/#{filename}"
  FileUtils.mkdir_p upload_dir_path
  FileUtils.rm_f upload_file_path

  uri = URI(url)
  Net::HTTP.start(source[:host], source[:port], use_ssl: true) do |http|
    request = Net::HTTP::Get.new uri
    http.request request do |response|
      break if response.code != '200'

      File.open upload_file_path, 'w' do |io|
        response.read_body do |chunk|
          io.write chunk
        end
      end
    end
  end

  return upload_file_path if File.exist?(upload_file_path)

  puts_error "File was not downloaded from '#{url}'"
  nil
end

def upload_file(upload_file_path, dest_container_id, dest_al_id, filename)
  md5 = Digest::MD5.new.file(upload_file_path)
  uploaded_chunk_hash = md5.hexdigest
  upload_form = {
    'upload_set' => Time.now.to_f.to_s,
    'file_hash' => uploaded_chunk_hash,
    'container_id' => dest_container_id,
    'activity_log_id' => dest_al_id,
    'activity_log_type' => 'activity_log__study_info_part',
    'chunk_hash' => uploaded_chunk_hash
  }

  upload_query = upload_form.dup
  query_merge_auth!(upload_query, dest)
  upload_url = build_uri(dest, path: '/nfs_store/chunk.json', query: upload_query)

  file = File.open(upload_file_path)
  file_ct = MIME::Types.type_for(filename).first&.content_type || DefaultMimeType

  uri = URI(upload_url)
  req = Net::HTTP::Post.new(uri)

  req.set_form([['upload', file, { filename: filename, content_type: file_ct }]], 'multipart/form-data')

  response = Net::HTTP.start(dest[:host], dest[:port], use_ssl: true) do |http|
    http.request(req)
  end

  if response.code != '200' && response.code != '201'
    puts_error "failed to upload file: #{response.code} - #{upload_url} "
    puts_error response.body
    nil
  else
    response.body
  end
end

def compare_cfile_lists(source_cfiles, dest_cfiles)
  slice_source_clist = source_cfiles.map { |m| m.slice(*ContainerListAttribs) }
  slice_dest_clist = dest_cfiles.map { |m| m.slice(*ContainerListAttribs) }
  if slice_source_clist == slice_dest_clist
    puts_info 'source and destination container lists match'
  else
    puts_info 'source and destination container lists differ'
    puts_warning (slice_dest_clist.map(&:to_a) - slice_source_clist.map(&:to_a)).map(&:to_h)

  end
end

def remove_mismatched_files_from(dest_cfiles, dest_al_id, dest_container_id, not_in:)
  df = dest_cfiles.map { |df| "#{df['path']}/#{df['file_name']} -- #{df['file_size']}" }
  nf = not_in.map { |df| "#{df['path']}/#{df['file_name']} -- #{df['file_size']}" }
  in_dest_not_source = df - nf

  to_disable = []
  in_dest_not_source.each do |fn|
    dest_cfile = dest_cfiles.find { |df| "#{df['path']}/#{df['file_name']} -- #{df['file_size']}" == fn }
    puts_warning "Disabling #{fn} - #{dest_cfile['id']} in destination container files -- #{dest_cfile['path']}/#{dest_cfile['file_name']} -- #{dest_cfile['file_size']}"
    to_disable << { 'id' => dest_cfile['id'], 'retrieval_type' => 'stored_file' }
  end

  return if in_dest_not_source.empty?

  send_files_to_trash to_disable, dest_al_id, dest_container_id
end

def handle_files_for(source_record, dest_record)
  is_source_embed = source_record.dig('embedded_item', 'item_type') == 'nfs_store__manage__container'
  is_dest_embed = dest_record.dig('embedded_item', 'item_type') == 'nfs_store__manage__container'

  if is_source_embed != is_dest_embed
    puts_warning "source embed and dest embed don't match"
    puts_plain source_record
    puts_plain dest_record

  elsif !is_source_embed
    puts_plain 'no embedded nfs store for this item'
    return
  end

  dest_al_id = dest_record['id']
  dest_master_id = dest_record['master_id']
  dest_container_id = dest_record.dig('embedded_item', 'id')
  puts_info "embeds an nfs store manage container #{dest_container_id} in activity log #{dest_al_id}"
  dest_clist = get_container_list(dest, dest_al_id, 'activity_log__study_info_part', dest_container_id)

  source_al_id = source_record['id']
  source_master_id = source_record['master_id']
  source_container_id = source_record.dig('embedded_item', 'id')
  puts_info "embeds an nfs store manage container #{source_container_id} in activity log #{source_al_id}"
  source_clist = get_container_list(source, source_al_id, 'activity_log__study_info_part', source_container_id)

  source_cfiles = source_clist['container_files']
  dest_cfiles = dest_clist['container_files']

  compare_cfile_lists source_cfiles, dest_cfiles

  # Remove files that are in the destination but not in the source
  remove_mismatched_files_from dest_cfiles, dest_al_id, dest_container_id, not_in: source_cfiles

  source_cfiles.each do |source_cfile|
    type_path = '/filestore/classification'
    source_query = { download_id: source_cfile['id'],
                     retrieval_type: 'stored_file',
                     activity_log_id: source_al_id,
                     activity_log_type: 'activity_log__study_info_part' }

    source_title_rec = get_target_record(source, 'nfs_store__manage__stored_file', type_path, source_container_id, source_master_id, query: source_query)
    puts_debug "Got source file: #{source_title_rec}"

    dest_cfile = dest_cfiles.find { |f| f['file_name'] == source_cfile['file_name'] }
    puts_debug "Got dest file original: #{dest_cfile}"

    if dest_cfile
      dest_query = { download_id: dest_cfile['id'],
                     retrieval_type: 'stored_file',
                     activity_log_id: dest_al_id,
                     activity_log_type: 'activity_log__study_info_part' }
      dest_title_rec = get_target_record(dest, 'nfs_store__manage__stored_file', type_path, dest_container_id, dest_master_id, query: dest_query)
      puts_debug "Got dest file: #{dest_title_rec}"

      slice_source_title_rec = source_title_rec.slice(*FileTitleAttribs)
      slice_dest_title_rec = dest_title_rec.slice(*FileTitleAttribs)
      if slice_source_title_rec == slice_dest_title_rec
        puts_info 'source and destination file titles match'
        next
      end

      # puts_warning slice_source_title_rec
      # puts_warning slice_dest_title_rec
      puts_warning "Updating file title: #{dest_title_rec.slice('id', 'title', 'description')} with #{source_title_rec.slice('id', 'title', 'description')}}"
      dest_query = { container_id: dest_container_id,
                     activity_log_id: dest_al_id,
                     activity_log_type: 'activity_log__study_info_part',
                     retrieval_type: 'stored_file' }

      title_id = dest_title_rec['id']
      path = "#{path_prefix(dest_master_id)}/filestore/classification/#{title_id}"
      form = {
        'option_type' => nil,
        'nfs_store_manage_stored_file[title]' => source_title_rec['title'],
        'nfs_store_manage_stored_file[description]' => source_title_rec['description'],
        'commit' => 'Save'
      }
      response = patch dest, path, dest_query, form

      if response.code != '200'
        puts_error "failed to update file title: #{response.code} - #{path} - #{dest_query}"
        next if ErrorContinue

        exit 10
      else
        puts_success "successful update of file title (#{path}): #{source_title_rec.slice('title', 'description')}"
      end
    else
      puts_info "Dest container file does not exist - #{source_cfile['file_name']}"
      puts_warning "Creating dest file with #{source_title_rec.slice('file_name', 'title', 'description')}}"

      download_id = source_cfile['id']
      filename = source_cfile['file_name']

      upload_file_path = download_file(download_id, filename, source_al_id, source_container_id)
      next unless upload_file_path

      res = upload_file upload_file_path, dest_container_id, dest_al_id, filename

      if res
        puts_success "Uploaded file successfully: #{res}"
      else
        next if ErrorContinue

        exit 10
      end
    end
  end
  nil
end

#########
@puts_indent = 0

def indent_str
  res = ''
  @puts_indent.times { res += ' ' }
  res
end

def puts_error(str)
  puts "#{indent_str}#{str.to_s.red}"
end

def puts_info(str)
  puts "#{indent_str}#{str.to_s.light_blue}"
end

def puts_warning(str)
  puts "#{indent_str}#{str.to_s.yellow}"
end

def puts_success(str)
  puts "#{indent_str}#{str.to_s.green}"
end

def puts_plain(str)
  puts "#{indent_str}#{str}"
end

def puts_debug(str)
  return unless Debug

  puts "#{indent_str}#{str}"
end

##############

path = '/reports/study_info__study_info_parts.json'
query = {
  'search_attrs[_report_id_]' => ''
}
response = get source, path, query

if response.code != '200'
  puts_error "failed to get the master records: #{response.code} - #{path} "
  exit 10
end

results_res = JSON.parse(response.body)
results = results_res['results']
puts_success "==== Got source results (#{results.length}) ===="
puts_plain "Limited to sections: #{LimitToSections}" if LimitToSections

results.each do |result|
  @puts_indent = 0
  src_master_id = result['master_id']
  study_info_id = result['study_info_id']

  next if LimitToSections && !LimitToSections.include?(study_info_id)

  puts_info "Section: #{study_info_id}"
  @puts_indent = 2
  # Get the study info pages for this study info master

  path = "/masters/#{src_master_id}/activity_log/study_info_parts.json"
  query = {}
  response = get source, path, query

  if response.code != '200'
    puts_error "failed to get the study info part records: #{response.code} - #{path} "
    next if ErrorContinue

    exit 10
  end

  als_res = JSON.parse(response.body)
  parts = als_res['activity_log__study_info_parts']

  # Find out if the master exists already
  path = "/masters/#{study_info_id}.json"
  query = {
    type: 'study_info_id'
  }
  response = get dest, path, query

  case response.code
  when '200'
    study_info_res = JSON.parse(response.body)
    study_info = study_info_res['master']
    puts_plain "found destination library #{study_info_id}"
  when '404'
    form = {
      'master[embedded_item][study_info_id]' => study_info_id
    }
    path = '/masters/create.json'
    response = post dest, path, {}, form

    if response.code != '200'
      puts_error "failed to create a new master record: #{response.code} - #{path} "
      next if ErrorContinue

      exit 10
    end

    study_info_res = JSON.parse(response.body)
    study_info = study_info_res['master']
    puts_success "created destination library #{study_info['study_info_id']} - #{study_info['master_id']}"
  else
    puts_error "failed to get the target study info record: #{response.code} - #{path} "
    next if ErrorContinue

    exit 10
  end

  dest_master_id = study_info['id']
  all_dest_parts = []
  # Add new or find pages for the new (or found) library
  parts.each do |source_part|
    @puts_indent = 4
    part_slug = source_part['slug']
    part_title = source_part['title']
    part_elt = source_part['extra_log_type']

    if part_slug && SkipSlugs.include?(part_slug)
      puts_info "skipping slug: #{part_slug}"
      next
    end

    puts_info "Study Info Part: #{part_slug || part_title || part_elt} - ##{source_part['master_id']} - ##{src_master_id} - #{study_info_id}"
    if source_part['disabled']
      puts_info 'is disabled - skipping'
      next
    end

    # Does the destination part slug exist?
    path = "/masters/#{dest_master_id}/activity_log/study_info_parts.json"
    query = {
      # type: 'study_info_id'
    }
    response = get dest, path, query
    if response.code != '200'
      puts_error "failed to get the destination study info part records: #{response.code} - #{path} "
      next if ErrorContinue

      exit 10
    end

    @puts_indent = 6

    to_type = 'activity_log__study_info_part'
    to_type_path = 'activity_log__study_info_parts'
    dest_parts_res = JSON.parse(response.body)
    dest_parts = dest_parts_res[to_type_path]
    puts_debug "existing #{dest_parts.map { |r| (r['slug'] || r['title'] || r['extra_log_type']) }}"
    puts_debug "looking for: #{part_slug || part_title || part_elt}"
    dest_part = dest_parts.find { |r| (r['slug'] || r['title'] || r['extra_log_type']).downcase == (part_slug || part_title || part_elt).downcase }

    new_part = source_part.slice(*part_attribs)

    add_or_update = false
    update_this = nil
    if dest_part
      puts_plain "found dest part: #{dest_part['slug'] || dest_part['title'] || dest_part['extra_log_type']} for #{part_slug || part_title || part_elt} - checking if the data matches"
      # Does it match?
      to_id = dest_part['id']
      sliced_dest_part = dest_part.slice(*part_attribs)

      if sliced_dest_part.merge(new_part) != sliced_dest_part && (!CompareDates || dest_part['updated_at'] <= source_part['updated_at'])
        puts_plain 'From record does not match destination record - will update'
        add_or_update = true
        puts_warning new_part
        puts_warning sliced_dest_part

        update_this = "/#{to_id}"
      end

    else
      add_or_update = true
    end

    if add_or_update
      # Slug does not exist in the destination - create a new part
      elt = new_part['extra_log_type']
      form = new_part
      path = "/masters/#{dest_master_id}/activity_log/study_info_parts#{update_this}.json"
      query = { extra_type: elt }

      form = fix_form(form, to_type)

      done = update_this ? 'update' : 'create'

      query = {}
      puts_debug form

      response = if update_this
                   done = 'update'
                   patch dest, path, query, form
                 else
                   done = 'add'
                   post dest, path, query, form
                 end
      if response.code != '200'
        puts_error "failed to #{done} activity log part record: #{response.code} - #{path}\n#{form}\n#{response}"
        next if ErrorContinue

        exit 10
      end
      dest_part_res = JSON.parse(response.body)
      dest_part = dest_part_res['activity_log__study_info_part']
      puts_success "success #{done} of dest part: #{dest_part['slug'] || dest_part['title'] || dest_part['extra_log_type']} - #{dest_part['master_id']} - #{dest_part['id']}"
    end

    all_dest_parts << dest_part

    # We don't do anything with the model references for file containers
    if ['supporting_files', 'supporting-files'].include?(part_elt)
      puts_info 'is a supporting-files container - skipping'
      next
    end

    # For each of the model references add it if needed
    mrs = source_part['model_references']
    dest_mrs = dest_part['model_references']

    excess_mrs = dest_mrs.reject { |mr| mr['disabled'] }.map { |mr| mr['to_record_data'] } - mrs.reject { |mr| mr['disabled'] }.map { |mr| mr['to_record_data'] }
    unless excess_mrs.empty?
      puts_warning "Destination has more subsections than the source: #{excess_mrs}"
      puts_debug "mrs = #{mrs.map { |v| v['to_record_data'] }}"
      puts_debug "dest_mrs = #{dest_mrs.map { |v| v['to_record_data'] }}"
    end

    idx = -1

    mrs.each do |mr|
      idx += 1
      @puts_indent = 8
      to_type_pl = mr['to_record_type_us_plural']
      to_type = mr['to_record_type_us']
      to_type_path = to_type_pl.gsub('dynamic_model__', '').gsub('__', '/')
      to_id = mr['to_record_id']
      to_master_id = mr['to_record_master_id']
      to_data = mr['to_record_data']
      from_record_type = mr['from_record_type_us']

      if to_data.nil? || to_data.empty?
        puts_warning "The referenced model has no data - using the index instead #{idx}"
        matched_dest_mr = dest_mrs[idx]
      else
        puts_info "Matching: #{to_data}"
        matched_dest_mr = dest_mrs.find { |r| r['to_record_data'] == to_data }
      end
      @puts_indent = 10

      if to_type_pl == 'nfs_store__manage__containers'
        puts_info 'is a nfs store container - skipping'
        next
      elsif !from_record_type
        puts_info 'is a shared item - skipping'
        next
      elsif mr['disabled']
        puts_info 'is disabled - skipping'
        puts_error 'but dest is not disabled' unless matched_dest_mr['disabled']
        next
      end

      # Get the source data
      use_master_id = to_master_id && src_master_id
      source_record = get_target_record(source, to_type, to_type_path, to_id, use_master_id)
      unless source_record
        next if ErrorContinue

        exit 22
      end

      if source_record['disabled']
        puts_info 'to record is disabled - skipping'
        next
      end

      if source_record['description']
        source_record['description'] = source_record['description']&.gsub("#{source[:protocol]}://#{source[:host]}", '')
      end

      new_to_record = source_record.dup

      delete_atts.each do |a|
        new_to_record.delete(a)
      end

      ### See if the record exists on the destination and if so, does it match?

      update_this = nil
      if matched_dest_mr
        puts_plain "matched model reference (#{to_data}) - checking if the data matches"
        to_id = matched_dest_mr['to_record_id']
        dest_record = get_target_record(dest, to_type, to_type_path, to_id, to_master_id)
        orig_dest_record = dest_record.dup
        unless dest_record
          puts_error "Destination record not found from model reference to_record_id #{to_id}"
          next if ErrorContinue

          exit 22
        end

        handle_files_for(source_record, dest_record)

        delete_atts.each do |a|
          dest_record.delete(a)
        end

        if dest_record.merge(new_to_record) == dest_record || (CompareDates && dest_record['updated_at'] > source_record['updated_at'])
          puts_info 'To record matches destination record - skipping'
          next
        end

        puts_warning new_to_record
        puts_warning dest_record

        update_this = "/#{to_id}"
      end

      part_ref_type = from_record_type.sub('__', '/')
      dest_part_id = dest_part['id']
      path = "#{path_prefix(dest_master_id)}/#{to_type_path}#{update_this}.json"
      query = {}

      form = new_to_record.dup
      form.merge! ref_record_type: part_ref_type, ref_record_id: dest_part_id
      form = fix_form(form, to_type)
      puts_debug form

      response = if update_this
                   done = 'update'
                   patch dest, path, query, form
                 else
                   done = 'add'
                   post dest, path, query, form
                 end
      if response.code != '200'
        puts_error "failed to #{done} new destination model ref: #{response.code} - #{path} "
        next if ErrorContinue

        exit 10
      else
        puts_success "successful #{done} of destination model ref (#{path}): #{to_data}"
      end
    end
    @puts_indent = 6
    ##################
    excess_parts = all_dest_parts.reject { |p| p['disabled'] }.map { |p| p['slug'] } - parts.reject { |p| p['disabled'] }.map { |p| p['slug'] }
    next if excess_parts.empty?

    puts_warning "Destination has more parts than the source: #{excess_parts}"
    puts_debug "parts = #{parts.map { |v| v['slug'] }}"
    puts_debug "all_dest_parts = #{all_dest_parts.map { |v| v['slug'] }}"
  end
end
