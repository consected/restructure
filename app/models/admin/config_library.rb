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

  after_commit :restart_server

  def self.content_named category, name, format: nil
    l = where(name: name, category: category, format: format).first

    raise FphsException.new "No config library in category #{category} named #{name} with format #{format || '(nil)'}" unless l

    l.options
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

    def restart_server
      AppControl.restart_server
    end


end
