# frozen_string_literal: true

class SaveTriggers::CreateFilestoreContainer < SaveTriggers::SaveTriggersBase
  attr_accessor :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids,
                :master, :name, :create_with_role, :skip_if_exists

  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    self.master = item.master

    self.create_with_role = config[:create_with_role]
    self.skip_if_exists = config[:skip_if_exists]
    self.name = config[:name]

    # TODO: understand why label is unused
    # self.label = config[:label]

    # If name is defined as an array, then get the attributes instead to build the name
    # Otherwise, run it through the standard substitution or Hash reference lookup handling
    self.name = if name.is_a? Array
                  atts = item.attributes
                  name.map { |i| atts.keys.include?(i) ? atts[i] : i }.join(' -- ')
                else
                  FieldDefaults.calculate_default item, name
                end

    self.name = name.gsub(%r{[/.]}, '-')
  end

  def perform
    return lookup_existing.present? if skip_if_exists

    container = NfsStore::Manage::Container.create_in_current_app user: item.master_user,
                                                                  name: name,
                                                                  extra_params: {
                                                                    master: master,
                                                                    create_with_role: create_with_role
                                                                  }

    ModelReference.create_with item, container, force_create: true
  end

  #
  # Returns list of references for a container with a matching name in
  # this master or for any container created by the current user (user_is_creator)
  # @return [Array]
  def lookup_existing
    filter_by = {
      name: name
    }

    pass_options = {
      to_record_type: 'nfs_store__manage__container',
      filter_by: filter_by,
      active: true
    }

    case skip_if_exists
    when 'master'
      ModelReference.find_references master, **pass_options
    when 'user_is_creator'
      pass_options[:ref_created_by_user] = true
      ModelReference.find_references item, **pass_options
    end
  end
end
