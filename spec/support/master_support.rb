# frozen_string_literal: true

require "#{::Rails.root}/spec/support/seeds"
require "#{::Rails.root}/spec/support/user_support"

module MasterSupport
  include ::UserSupport

  def seed_database
    Rails.logger.info 'Starting seed setup in Master Support'
    # puts "#{Time.now} Starting seed setup in Master Support"
    SeedSupport.setup
  end

  def add_default_app_config(app_type, config_name, config_value)
    Admin::AppConfiguration.add_default_config app_type, config_name, config_value, @admin
  end

  def edit_form_prefix
    @edit_form_prefix = nil
  end

  def edit_form_name
    @edit_form_name = nil
  end

  def objects_symbol
    object_class.to_s.ns_underscore.pluralize.to_sym
  end

  def object_symbol
    object_class.to_s.ns_underscore.to_sym
  end

  def objects_short_name
    object_class.to_s.split('::').last.underscore.pluralize
  end

  def custom_edit_form_prefix
    "admin/#{objects_short_name.pluralize}"
  end

  def saved_item_template
    '_index'
  end

  def item_id
    item.to_param
  end

  def edit_form_admin
    @edit_form_admin = nil unless defined? @edit_form_admin
    @edit_form_admin || "#{edit_form_prefix || custom_edit_form_prefix}/_form"
  end

  def edit_form_user
    "#{edit_form_prefix || objects_symbol}/#{edit_form_name || '_edit_form'}"
  end

  def create_sources(name)
    i = "#{name}_source"
    gs = Classification::GeneralSelection.active.where(item_type: i, value: %w[nfl nflpa])
    if gs.empty?
      Classification::GeneralSelection.create item_type: i, name: 'NFL', value: 'nfl', current_admin: auto_admin,
                                              create_with: true
      Classification::GeneralSelection.create item_type: i, name: 'NFLPA', value: 'nflpa', current_admin: auto_admin,
                                              create_with: true
    else
      gs.update_all create_with: true
      Rails.cache.clear
    end
  end

  def put_valid_attribs
    valid_attribs
  end

  def let_user_create_master(user = nil)
    user ||= @user
    return if user.can? :create_master

    Admin::UserAccessControl.create!(app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :create_master, current_admin: @admin, user: user)

    expect(user.can?(:create_master)).to be_truthy
  end

  def create_master(user = nil, att = nil)
    user ||= @user || create_user.first

    user.app_type ||= Admin::AppType.active.first

    att ||= { msid: rand(1_000_000_000), pro_id: rand(1_000_000_000) }

    master = Master.new att
    master.current_user = user
    master.save!

    setup_access
    setup_access :trackers unless user.has_access_to? :create, :table, :trackers

    @master_id = master.id
    @master = master
  end

  def create_items(from_list = :list_valid_attribs, master_or_admin = nil, expect_failures = nil)
    @created_count = 0
    @exceptions = []
    @list = send(from_list)
    @created_items = []

    @list.each do |l|
      res = create_item l, master_or_admin
      if res
        @created_count += 1
        @created_items << res
      end
    rescue StandardError => e
      @exceptions << e
      unless expect_failures
        puts "Exceptions in create_items for #{l.inspect}: #{e.inspect} #{e.backtrace.join("\n")}"
        raise e
      end
    end

    @created_items
  end

  def check_all_records_failed
    expect(@exceptions.length).to eq(@list.length), 'Not every test caused the record creation to fail'

    @exceptions.each do |e|
      expect(e).to be_a(ActiveRecord::StatementInvalid) | be_a(ActiveRecord::RecordInvalid)
    end

    expect(@created_count).to eq 0
  end

  def opt(bd)
    (rand(1000) > 500 ? bd : nil)
  end

  def invalid_attribs
    pick_from list_invalid_attribs
  end

  def invalid_update_attribs
    pick_from list_invalid_update_attribs
  end

  def valid_attribs
    pick_from list_valid_attribs
  end

  def new_attribs_downcase
    @new_attribs.each { |k, att| @new_attribs[k] = (att.is_a?(String) ? att.downcase : att) }
  end

  def resp
    JSON.parse(response.body)
  end

  def pick_one
    res = (rand(1000) > 500)
    Rails.logger.info "Pick one returned #{res}"
    res
  end

  def pick_from(list)
    r = rand(list.length)
    list[r]
  end

  def first_names
    %w[Glenn Mose Leandro Damien Claude Kelvin Rudolf Shad Wm Nathanial Dominick
       Carlton Arthur Jame Doug Tod Nickolas Israel Domingo Donovan Scott Carol Cesar Ismael Michael Reyes Blake Odis Brant Luther Mauricio Olin Victor Milford Tony Aubrey Dana Berry Salvador Parker Marcelo Ray Gerard Miguel Cornelius Coleman Dwayne Wilbert Leonardo Bud]
  end

  def last_names
    %w[Basilio Portillo Just Northup Ankrom Seto Dominick Dehn Ramirez Polley Detwiler
       Mahone Mchenry Fink Keesling Shaikh Mazurek Brashears Arel Perrella Ver Fitzgibbon Tefft Burruel Boulter Klatt Linger Kyser Silversmith Tregre Millett Welk Down Bate Mchaney Pope Wagoner Mcdougal Nolan Melendez Imler Way Crimmins Korando Cohen Keisler Hardman Sallis Pinder Acey]
  end

  def other_names
    %w[Dingus Vella Bowland Sackett Arias Pannell Swinehart Bezio Goble Greenley Sides
       Utz Andres Witt Mraz Cheever Muma Diana Weston Lennox Carasco Stavros Platts Bunyard Bahena Marciano Normandeau Small Sellars Bahr Yard Hankerson Abram Bouffard Arruda Faulkenberry Sirmans Mabon Chavarin Uphoff Billingslea Montandon Neilson Repka Delucia Juarbe Govan Mattern Bendel Flatley]
  end

  def colleges
    ['harvard', 'dartmouth', 'yale', 'ucla', 'boston college', 'boston university', 'northeastern', 'mit']
  end

  def self.disable_existing_records(name, opt = {})
    ext = opt[:external_id_attribute]
    admin = opt[:current_admin] || Admin.active.first

    r = if name != :all
          ExternalIdentifier.where('name=? or external_id_attribute=?', name, ext)
        else
          ExternalIdentifier.active
        end
    r.each do |a|
      # Also clean up any associated activity logs
      als = ActivityLog.active.where(item_type: a.name.singularize)
      als.each do |al|
        al.disabled = true
        al.current_admin = admin
        al.save
      end

      a.name += '_olds'
      a.external_id_attribute += '_old_id'
      a.disabled = true
      a.current_admin = admin
      a.save!
    end
  end
end
