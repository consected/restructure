class ReportBase < ActiveRecord::Base

  self.abstract_class = true
  # Provide a modified human name for an instance
  def human_name

    if respond_to?(:rec_type) && self.rec_type
      rec_type.underscore.humanize.titleize
    else
      self.class.human_name
    end
  end

  def self.human_name
    cn = self.name

    cn = cn.split('::').last
    cn.underscore.humanize.titleize
  end

  def item_type_us
    self.item_type.ns_underscore
  end

  def item_type
    self.class.name.singularize.ns_underscore
  end

end
