class Admin::AdminBase < ActiveRecord::Base

  self.abstract_class = true

  ValidAdminModules = %w(Admin Classification Messaging)


  def self.class_from_name name
    name = name.classify
    ValidAdminModules.each do |mn|
      mod = Object.const_get(mn)
      res = mod.const_get(name) rescue nil
      return res if res.is_a? Class
    end

    name.constantize
  end

end
