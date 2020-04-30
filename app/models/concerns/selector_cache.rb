# frozen_string_literal: true

module SelectorCache
  extend ActiveSupport::Concern

  included do
    after_initialize :init_vars_selector_cache
    before_save :invalidate_cache
    before_create :invalidate_cache

    scope :enabled, -> { all.where('disabled is null OR disabled = FALSE') }
  end

  class_methods do
    def selector_cache?
      true
    end

    def downcase_if_string(val)
      if val.is_a? String
        val.downcase
      else
        val
      end
    end

    def gen_cache_key
      to_s
    end

    def array_cache_key
      logger.debug "Getting #{self} array cache key"
      "#{self}_array"
    end

    def array_pair_cache_key
      "#{self}_hash"
    end

    def collection_cache_key
      logger.debug "Getting #{self} collection cache key"
      "#{self}_collection"
    end

    def nv_pair_cache_key
      "#{self}_nameval"
    end

    def nv_user_id_cache_key
      "#{self}_namevaluserid"
    end

    def nv_all_cache_key
      "#{self}_namevalall"
    end

    def attributes_cache_key
      "#{self}_attributes"
    end

    def selector_array(conditions = nil, attribute = :name)
      ckey = "#{array_cache_key}#{conditions}:#{attribute}"
      Rails.cache.fetch(ckey) do
        res = enabled
        res = res.where(conditions) if conditions.present?
        res.collect { |c| c.send(attribute) }
      end
    end

    def selector_array_pair(conditions = nil)
      ckey = "#{array_pair_cache_key}#{conditions}"

      Rails.cache.fetch(ckey) do
        enabled.where(conditions).collect { |c| [c.name, c.id] }
      end
    end

    def selector_name_value_pair(conditions = nil)
      ckey = "#{nv_pair_cache_key}#{conditions}"

      Rails.cache.fetch(ckey) do
        enabled.where(conditions).collect { |c| [c.name, downcase_if_string(c.value)] }
      end
    end

    def selector_name_value_pair_no_downcase(conditions = nil)
      ckey = "#{nv_pair_cache_key}-nd-#{conditions}"

      Rails.cache.fetch(ckey) do
        enabled.where(conditions).collect { |c| [c.name, c.value] }
      end
    end

    def selector_attributes(attributes, conditions = nil)
      ckey = "#{attributes_cache_key}#{attributes}#{conditions}"

      Rails.cache.fetch(ckey) do
        enabled.where(conditions).collect do |c|
          a = []
          attributes.each do |att|
            a << c.send(att)
          end
          a
        end
      end
    end

    def selector_collection(conditions = nil)
      ckey = "#{collection_cache_key}#{conditions}"

      Rails.cache.fetch(ckey) do
        enabled.where(conditions)
      end
    end

    def all_name_value_enable_flagged(conditions = nil)
      ckey = "#{nv_all_cache_key}#{conditions}"

      Rails.cache.fetch(ckey) do
        if conditions && conditions[:disabled] == false
          res = active
          conditions.delete :disabled
        else
          res = all
        end

        res.where(conditions).collect do |c|
          name = ''
          if c.respond_to?(:parent_name)
            v = c.id
            vlabel = "(#{c.parent_name}) "
            name = c.name
          elsif c.respond_to?(:value)
            v =  c.value
            name = c.name
          else
            v = c.id
            name = c.name
          end

          name = c.full_label if c.respond_to?(:full_label)

          ["#{vlabel}#{name} #{c.disabled ? '[disabled]' : ''}", downcase_if_string(v)]
        end.sort
      end
    end

    def name_user_id_value(conditions = nil)
      ckey = "#{nv_user_id_cache_key}-nd-#{conditions}"

      Rails.cache.fetch(ckey) do
        enabled.where(conditions).collect { |c| [c.name, c.user_id, c.value] }
      end
    end

    def name_for(value)
      res = selector_name_value_pair.select { |p| p.last == value }
      res.length >= 1 ? res.first.first : nil
    end

    def value_for(name)
      res = selector_name_value_pair.select { |p| p.first == name }
      res.length >= 1 ? res.first.last : nil
    end

    def user_value_for(name, user_id: nil, app_type_id: nil)
      conditions = nil
      conditions = { app_type_id: app_type_id } if app_type_id
      res = name_user_id_value(conditions).select { |p| p.first == name && (p[1] == user_id) }
      # be sure to return a blank string for a result if one was received, or nil otherwise
      res.length >= 1 ? (res.first.last || '') : nil
    end
  end

  def invalidate_cache
    logger.info "Selector added or updated (#{self.class.name}). Invalidating cache."
    # Unfortunately we have no way to clear pattern matched keys with memcached so we just clear the whole cache
    Rails.cache.clear
  end

  protected

  def init_vars_selector_cache
    instance_var_init :prevent_create
    instance_var_init :prevent_edit
    instance_var_init :label
    instance_var_init :id_formatter
  end
end
