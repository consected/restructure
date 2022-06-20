#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'active_support/core_ext/hash/keys'

source = {
  username: ENV['SRC_API_USER'],
  token: ENV['SRC_API_TOKEN'],
  app_type: 1,
  protocol: 'http',
  host: 'localhost',
  port: '3001'
}

dest = {
  username: ENV['DEST_API_USER'],
  token: ENV['DEST_API_TOKEN'],
  app_type: 1,
  protocol: 'http',
  host: 'localhost',
  port: '3001'
}

failures = []

def net_class(target)
  Net.const_get target[:protocol].upcase
end

def build_uri(target, path:, query: nil)
  query = URI.encode_www_form(query) if query
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
  net_class(target).get_response(uri)
end

def post(target, path, query = {}, form = {})
  host = target[:host]
  port = target[:port]

  query.merge!(
    user_email: target[:username],
    user_token: target[:token],
    use_app_type: target[:app_type]
  )

  uri = build_uri(target, path: path, query: query)
  net_class(target).post_form(uri, form)
end

path = '/masters.json'
query = {
  mode: 'SIMPLE',
  commit: 'search',
  'master[general_infos_attributes][0][first_name]' => 'ed'
}
response = get source, path, query

if response.code != '200'
  puts "failed to get the master records: #{response.code} - #{path} "
  exit 10
end

masters = JSON.parse(response.body)
masters['masters'].each do |master|
  # Create a new master and player_info record
  player_info = master['player_infos']&.first

  new_details = {}
  if player_info
    new_details = player_info.symbolize_keys.slice(:first_name, :last_name, :birth_date, :death_date, :accuracy_score, :source)
    new_details[:first_name] = new_details[:first_name].reverse
    new_details[:last_name] = new_details[:last_name].reverse
    new_details.transform_keys! { |k| "master[embedded_item][#{k}]" }
  end
  form = new_details
  path = '/masters/create.json'
  response = post dest, path, {}, form

  if response.code != '200'
    puts "failed to create a new master record: #{response.code} - #{path} "
    exit 10
  end

  new_master_res = JSON.parse(response.body)
  new_master = new_master_res['master']
  new_master_id = new_master['id']

  # Add the player contacts
  new_player_contacts = []

  player_contacts = master['player_contacts']
  player_contacts.each do |player_contact|
    new_details = player_contact.symbolize_keys.slice(:data, :rec_type, :rank, :source)
    new_details.transform_keys! { |k| "player_contact[#{k}]" }

    form = new_details
    path = "/masters/#{new_master_id}/player_contacts.json"
    response = post dest, path, {}, form

    if response.code != '200'
      puts "failed to create a new player contact record: #{response.code} - #{path} "
      exit 10
    end

    # Result is all the player contact records in this master
    new_pc_res = JSON.parse(response.body)

    new_pc = new_pc_res['player_contact']
    new_player_contacts << new_pc
  end

  # Create a copy of the phone log records
  path = "/masters/#{master['id']}/activity_log/player_contact_phones.json"
  query = {}
  response = get source, path, query

  if response.code != '200'
    puts "failed to get the phone log records: #{response.code} - #{path} "
    exit 10
  end

  als = JSON.parse(response.body)

  als['activity_log__player_contact_phones'].each do |al|
    # Find the newly created player contact record with this data, so we can reference it
    new_pc = new_player_contacts.first { |pc| pc['data'] == al['data'] }
    next unless new_pc

    new_pc_id = new_pc['id']
    elt = al['extra_log_type']
    new_al = al.symbolize_keys.slice(:extra_log_type, :select_call_direction, :select_who, :called_when, :select_result, :select_next_step, :notes)
    path = "/masters/#{new_master_id}/player_contacts/#{new_pc_id}/activity_log/player_contact_phones.json"
    query = { extra_type: elt }

    response = post dest, path, {}, form

    if response.code != '200'
      puts "failed to create activity log record: #{response.code} - #{path} "
      exit 10
    end

    puts "Added new master record #{dest[:protocol]}://#{dest[:host]}:#{dest[:port]}/masters/#{new_master_id}"
  end
end
