class ReportBase < ActiveRecord::Base
  self.abstract_class = true
  # Provide a modified human name for an instance
  def human_name
    if respond_to?(:rec_type) && rec_type
      rec_type.underscore.humanize.captionize
    else
      self.class.human_name
    end
  end

  class << self
    attr_writer :definition
  end

  class << self
    attr_reader :definition
  end

  def definition
    self.class.definition
  end

  def self.human_name
    cn = name

    cn = cn.split('::').last
    cn.underscore.humanize.captionize
  end

  def item_type_us
    item_type.ns_underscore
  end

  def item_type
    self.class.name.singularize.ns_underscore
  end

  def model_data_type
    :report
  end
end
