# frozen_string_literal: true

module ActivityLogControllerHandler
  extend ActiveSupport::Concern
  include GeneralDataConcerns

  class_methods do
    # Annoyingly this needs to be forced, since const_set during controller generation does not
    # appear to set the parent class correctly, unlike for models
    # Possibly this is a Rails specific override, but the parent is set correctly
    # when a controller is created as a file in a namespaced folder, so rather
    # than fighting it, just force the known parent here.

    def item_controller
      @item_controller = parent_type.to_s.pluralize
    end

    def item_rec_type
      @item_rec_type = parent_rec_type.to_s
    end

    def parent_type
      @parent_type = definition.item_type.to_sym
    end

    def parent_rec_type
      @parent_rec_type = definition.rec_type.to_sym
    end
  end

  def item_controller
    self.class.item_controller
  end

  def item_rec_type
    self.class.item_rec_type
  end
end
