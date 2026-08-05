module OptionConfigs
  class BaseNamedConfiguration < OptionConfigs::BaseOptions
    include OptionsHandler

    attr_accessor :owner, :use_hash_config

    #
    # Hash-like access to configuration attributes by key name.
    # Enables backward compatibility with code that expects Hash-like access
    # on individual named configuration items, e.g. `named_config[:caption]`
    # @param [Symbol | String] key - the attribute name
    # @return [Object] the attribute value, or nil if not recognized
    def [](key)
      sym_key = key.to_sym
      return nil unless respond_to?(sym_key)

      send(sym_key)
    end

    # Check if a key is a recognized attribute with a non-nil value.
    # Matches Hash#key? semantics for configs parsed from YAML:
    # a key is "present" only when it was actually defined (non-nil).
    # @param [Symbol | String] key - the attribute name
    # @return [Boolean]
    def key?(key)
      sym_key = key.to_sym
      self.class.option_types[:simple]&.include?(sym_key) && !send(sym_key).nil?
    end

    alias has_key? key?

    # Set a configuration attribute by key.
    # Enables backward compatibility with template code that mutates
    # field option configs, e.g. `options[:include_blank] = true`.
    # Only allows setting attributes declared via configure_attributes.
    # @param [Symbol | String] key - the attribute name
    # @param [Object] value - value to set
    def []=(key, value)
      sym_key = key.to_sym
      return unless respond_to?(:"#{sym_key}=")

      send(:"#{sym_key}=", value)
    end

    #
    # Convert all configured attributes to a plain Hash.
    # Mirrors OptionsHandler::Configuration#to_h for named configurations.
    # @return [Hash{Symbol => Object}]
    def to_h
      res = {}
      self.class.option_types[:simple].each { |k| res[k] = send(k) }
      res
    end

    alias to_hash to_h

    # Hash-compatible dig for nested access on named configurations.
    # @param keys [Array<Symbol>] nested key path
    # @return [Object, nil]
    def dig(*keys)
      first = keys.shift
      val = self[first]
      return val if keys.empty? || val.nil?

      val.respond_to?(:dig) ? val.dig(*keys) : nil
    end

    #
    # Equality comparison: compare as plain Hash for backward compatibility
    # with code that previously stored raw Hashes instead of NamedConfiguration objects.
    # @param other [Object] value to compare against
    # @return [Boolean]
    def ==(other)
      return filtered_hash == other if other.is_a?(Hash)

      super
    end

    #
    # Return a Hash containing only non-nil attribute values.
    # Useful for serialization where nil values should be omitted.
    # @return [Hash{Symbol => Object}]
    def filtered_hash
      to_h.reject { |_k, v| v.nil? }
    end

    # Duplicate as a plain Hash for backward compatibility with callers that
    # historically treated named configurations as mutable hashes.
    # @return [Hash{Symbol => Object}]
    def dup
      filtered_hash.deep_dup
    end

    # Deep duplicate as a plain Hash for compatibility with callers that merge
    # nested field option configs after duplicating them.
    # @return [Hash{Symbol => Object}]
    def deep_dup
      filtered_hash.deep_dup
    end

    # Merge with another hash-like object and return a plain Hash.
    # @param other [Hash, #to_h, #filtered_hash]
    # @return [Hash{Symbol => Object}]
    def merge(other)
      filtered_hash.merge(coerce_hash(other))
    end

    def config_text
      return super unless owner

      owner.config_text
    end

    def config_text=(value)
      unless owner
        super
        return
      end

      owner.config_text = value
    end

    def persisted?
      return true unless owner

      owner.persisted?
    end

    # Check for keys in hash_configuration that don't match any declared
    # configure_attributes. Reports each unrecognized key as a warning
    # on the owner (BaseConfiguration) via failed_config.
    # Called after setup_from_hash_config so that declared attributes are known.
    def validate_recognized_keys
      return unless hash_configuration.is_a?(Hash)
      return unless owner&.respond_to?(:failed_config, true)

      recognized = self.class.option_types[:simple].to_set
      hash_configuration.each_key do |key|
        next if recognized.include?(key)

        owner.send(:failed_config, key, "unrecognized attribute '#{key}'", level: :warn)
      end
    end

    private

    def coerce_hash(other)
      return other.filtered_hash if other.respond_to?(:filtered_hash)
      return other.to_h if other.respond_to?(:to_h)

      other || {}
    end
  end
end
