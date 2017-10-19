module DynamicModelHandler

  extend ActiveSupport::Concern

  class_methods do
    # This is intentionally a class variable, to capture the model names for all dynamic models
    def model_names
      @model_names ||= []
    end

    def model_names= m
      @model_names = m
    end

    def model_name_strings
      model_names.map {|m| m.to_s}
    end

    def models
      @models ||= {}
    end

    def define_models

      begin
        dma = self.active
        logger.info "Generating models #{self.name} #{self.active.length}"
        puts "Generating models for #{self.name} #{self.active.length}"
        dma.each do |dm|
          dm.generate_model
        end
      rescue =>e
        Rails.logger.warn "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}\n#{e.backtrace.join("\n")}"
        puts "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}\n#{e.backtrace.join("\n")}"
      end

    end

    def routes_reload
      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!
    end

  end



  def model_def
    self.class.models[model_def_name]
  end

  def reload_routes
    self.class.routes_reload
  end


end
