class Admin::ConfigLibrary < Admin::AdminBase

  self.table_name = 'config_libraries'
  include AdminHandler

  def self.valid_formats
    %w(yaml html markdown sql)
  end

  validates :name, presence: true
  validates :format, presence: true
  validates :format, inclusion: { in: valid_formats }
  validate :unique_library

  after_commit :refresh_dependencies

  def self.content_named category, name, format: nil
    l = where(name: name, category: category, format: format).first

    raise FphsException.new "No config library in category #{category} named #{name} with format #{format || '(nil)'}" unless l

    l.options
  end

  # Directly substitute the library configurations into the supplied text
  # @param text [String] text that will be updated
  # @param format [Symbol] :yaml or :sql
  # @return [Array] list of Admin::ConfigLibrary instances that were substitued in
  def self.make_substitutions! text, format

    return unless text

    if format == :yaml
      prefix = '# '
    elsif format == :sql
      prefix = '-- '
      direct_sub = true
    end

    reg = /#{prefix}@library\s+([^\s]+)\s+([^\s]+)\s*$/
    res = text.match reg
    all_libs = []

    while res
      category = res[1].strip
      name = res[2].strip
      lib = Admin::ConfigLibrary.where(category: category, name: name, format: format).first
      all_libs << lib
      if direct_sub
        text.gsub!(res[0], lib.options || '')
      else
        text.gsub!(res[0], '')
      end
      res = text.match reg
    end

    all_libs
  end


  def is_yaml?
    self.format.to_s == 'yaml'
  end

  def parsed
    if content.present? && is_yaml?
      res = YAML.load(c)
    else
      res = {}
    end
  end


  private

    def unique_library

      l = self.class.active.where(name: self.name, category: self.category, format: self.format).first
      errors.add :name, "and format must be unique. Name: #{self.name}, category: #{self.category}, format: #{self.format}" if l && l.id != self.id

    end

    def refresh_dependencies
      return unless self.format.to_s == 'yaml'

      ms = []

      ActivityLog.active.each do |a|
        cl = ExtraLogType.config_libraries a
        ms << a if cl.include? self
      end

      DynamicModel.active.each do |a|
        cl = ExtraOptions.config_libraries a
        ms << a if cl.include? self
      end

      ms.each do |e|
        e.force_option_config_parse
      end

    end


end
