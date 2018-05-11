class UserBaseController < ApplicationController

  include FilterUtils

  before_action :authenticate_user!
  helper_method :object_name, :object_instance, :full_object_name, :extra_options

  protected
    # return the class for the current item
    # handles namespace if the item is like an ActivityLog:Something
    def primary_model
      if self.class.parent.name != 'Object'
        "#{self.class.parent.name}::#{object_name.camelize}".constantize
      else
        controller_name.classify.constantize
      end
    end

    def object_name
      controller_name.singularize
    end

    # notice the double underscore for namespaced models to indicate the delimiter
    # to remain consistent with the associations
    def full_object_name
      if self.class.parent.name != 'Object'
        "#{self.class.parent.name.underscore}__#{controller_name.singularize}"
      else
        controller_name.singularize
      end
    end

    # the association name from master to these objects
    # for example player_contacts or activity_log__player_contacts_phones
    # notice the double underscore for namespaced models to indicate the delimiter
    def objects_name

      if self.class.parent.name != 'Object'
        "#{self.class.parent.name.underscore}__#{controller_name}".to_sym
      else
        controller_name.to_sym
      end
    end

    def human_name
      if object_instance && object_instance.respond_to?(:human_name)
        object_instance.human_name
      else
        controller_name.singularize.humanize
      end
    end

end
