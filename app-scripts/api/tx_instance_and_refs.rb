#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'active_support/core_ext/hash/keys'

source = {
  username: ENV['SRC_API_USER'],
  token: ENV['SRC_API_TOKEN'],
  app_type: 57,
  protocol: 'https',
  host: 'vivadev.link',
  port: '443'
}

dest = {
  username: ENV['DEST_API_USER'],
  token: ENV['DEST_API_TOKEN'],
  app_type: 16,
  protocol: 'https',
  host: 'vivademoportal.net',
  port: '443'
  # app_type: 72,
  # protocol: 'http',
  # host: 'localhost',
  # port: 3001
}

failures = []

def build_uri(target, path:, query: nil)
  query = URI.encode_www_form(query) if query
  path = path.gsub(' ', '%20')
  uri_class = URI.const_get target[:protocol].upcase
  uri_class.build(host: target[:host], port: target[:port], path: path, query: query)
end

def get(target, path, query = {})
  query.merge!(
    user_email: target[:username],
    user_token: target[:token],
    use_app_type: target[:app_type]
  )

  uri = build_uri(target, path: path, query: query)
  Net::HTTP.get_response(uri)
end

def post(target, path, query = {}, form = {})
  query.merge!(
    user_email: target[:username],
    user_token: target[:token],
    use_app_type: target[:app_type]
  )

  uri = build_uri(target, path: path, query: query)
  Net::HTTP.post_form(uri, form)
end

path = '/reports/study_info__study_info_parts.json'
query = {
  'search_attrs[_report_id_]' => ''
}
response = get source, path, query

if response.code != '200'
  puts "failed to get the master records: #{response.code} - #{path} "
  exit 10
end

results_res = JSON.parse(response.body)
results = results_res['results']

results.each do |result|
  master_id = result['master_id']
  study_info_id = result['study_info_id']

  # Get the study info pages for this study info master

  path = "/masters/#{master_id}/activity_log/study_info_parts.json"
  query = {}
  response = get source, path, query

  if response.code != '200'
    puts "failed to get the study info part records: #{response.code} - #{path} "
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
    puts "found destination library #{study_info_id}"
  when '404'
    form = {
      'master[embedded_item][study_info_id]' => study_info_id
    }
    path = '/masters/create.json'
    response = post dest, path, {}, form

    if response.code != '200'
      puts "failed to create a new master record: #{response.code} - #{path} "
      exit 10
    end

    study_info_res = JSON.parse(response.body)
    study_info = study_info_res['master']
    puts "created destination library #{study_info['study_info_id']} - #{study_info['master_id']}"
  else
    puts "failed to get the target study info record: #{response.code} - #{path} "
    exit 10
  end

  dest_master_id = study_info['id']

  # Add new or find pages for the new (or found) library
  parts.each do |part|
    part_slug = part['slug']
    part_title = part['title']
    part_elt = part['extra_log_type']

    puts "in part: #{part_slug || part_title || part_elt} - #{part['master_id']} - #{master_id} - #{study_info_id}"
    if part['disabled']
      puts 'is disabled - skipping'
      next
    end

    # Does the destination part slug exist?
    path = "/masters/#{dest_master_id}/activity_log/study_info_parts.json"
    query = {
      # type: 'study_info_id'
    }
    response = get dest, path, query
    if response.code != '200'
      puts "failed to get the destination study info part records: #{response.code} - #{path} "
      exit 10
    end
    dest_parts_res = JSON.parse(response.body)
    dest_parts = dest_parts_res['activity_log__study_info_parts']
    puts "existing #{dest_parts.map { |r| (r['slug'] || r['title'] || r['extra_log_type']) }}"
    puts "looking for: #{part_slug || part_title || part_elt}"
    dest_part = dest_parts.find { |r| (r['slug'] || r['title'] || r['extra_log_type']).downcase == (part_slug || part_title || part_elt).downcase }

    if dest_part
      puts "found dest part: #{dest_part['slug'] || dest_part['title'] || dest_part['extra_log_type']} for #{part_slug || part_title || part_elt}"
    else
      # Slug does not exist in the destination - create a new part
      elt = part['extra_log_type']
      form = part.symbolize_keys.slice(:extra_log_type, :title, :description, :default_layout, :slug, :tag_select_allow_roles_access, :footer, :tag_select_page_tags, :disabled, :position_number, :extra_classes, :notes)
      path = "/masters/#{dest_master_id}/activity_log/study_info_parts.json"
      query = { extra_type: elt }
      form.transform_keys! { |k| "activity_log_study_info_part[#{k}]" }

      # Array fields need to be split into appropriate parameters
      array_fields = {}
      form.each do |k, v|
        next unless v.is_a? Array

        array_fields = v.map { |av| ["#{k}[]", av] }.to_h
      end

      # Remove the original entries for array fields
      array_fields.each_key do |k|
        form.delete k
      end

      # Add in the new multiple entries for each array field
      form.merge! array_fields

      response = post dest, path, {}, form
      if response.code != '200'
        puts "failed to create activity log part record: #{response.code} - #{path} "
        exit 10
      end
      dest_part_res = JSON.parse(response.body)
      dest_part = dest_part_res['activity_log__study_info_part']
      dest_parts << dest_part

      puts "created dest part: #{dest_part['slug'] || dest_part['title'] || dest_part['extra_log_type']} - #{dest_part['master_id']} - #{dest_part['id']}"

    end

    next if ['supporting_files', 'supporting-files'].include?(part_elt)

    # For each of the model references add it if needed
    mrs = part['model_references']
    dest_mrs = dest_part['model_references']

    # puts "part: #{part}"
    # puts "dest_part: #{dest_part}"
    puts "mrs = #{mrs.map { |v| v['to_record_data'] }}"
    puts "dest_mrs = #{dest_mrs.map { |v| v['to_record_data'] }}"
    mrs.each do |mr|
      to_type_pl = mr['to_record_type_us_plural']
      to_type = mr['to_record_type_us']
      to_type_path = to_type_pl.gsub('dynamic_model__', '').gsub('__', '/')
      to_id = mr['to_record_id']
      to_master_id = mr['to_record_master_id']
      to_data = mr['to_record_data']
      from_record_type = mr['from_record_type_us']
      if to_type_pl == 'nfs_store__manage__containers'
        puts 'is a nfs store container - skipping'
        next
      elsif !from_record_type
        puts 'is a shared item - skipping'
        next
      elsif  mr['disabled']
        puts 'is disabled - skipping'
        next
      end

      puts "try matching: #{to_data}"
      matched_dest_mr = dest_mrs.find { |r| r['to_record_data'] == to_data }
      if matched_dest_mr
        puts "matched ref: #{matched_dest_mr['to_record_data']}"
        next
      end

      path_pre = ''
      path_pre = "/masters/#{dest_master_id}" if to_master_id
      path = "#{path_pre}/#{to_type_path}/#{to_id}.json"
      query = {}
      response = get source, path, query
      if response.code != '200'
        puts "failed to get referenced to record: #{response.code} - #{path} "
        exit 10
      end
      to_record_res = JSON.parse(response.body)
      to_record = to_record_res[to_type]

      puts 'to record is disabled - skipping' if to_record['disabled']

      new_to_record = to_record
      delete_atts = %w[id created_at created_at_ts updated_at updated_at_ts user_id created_by_user_email created_by_user_name
                       creatable_model_references def_version embedded_item embedded_items human_name ids item_type
                       master_created_by_user master_created_by_user_email master_id model_data_type model_references
                       prevent_add_reference prevent_edit rank_name referenced_from resource_name source_name update_action
                       user_email user_id user_name user_preference vdef_version _created _general_selections _updated]

      delete_atts.each do |a|
        new_to_record.delete(a)
      end

      part_ref_type = from_record_type.sub('__', '/')
      dest_part_id = dest_part['id']
      path = "#{path_pre}/#{to_type_path}.json"
      query = {}
      form_prefix = to_type.gsub('__', '_')
      form = new_to_record.dup
      form.merge! ref_record_type: part_ref_type, ref_record_id: dest_part_id
      form.transform_keys! { |k| "#{form_prefix}[#{k}]" }

      response = post dest, path, query, form
      if response.code != '200'
        puts "failed to add new destination model ref: #{response.code} - #{path} "
        exit 10
      else
        puts "added new destination model ref (#{path}): #{to_data}"
      end
    end
    ##################
  end
end
