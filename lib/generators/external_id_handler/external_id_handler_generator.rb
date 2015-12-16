class ExternalIdHandlerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  
  
  def copy_model_file
    template "external_id_handler.rb", "app/models/#{file_name}.rb"    
  end
  
  def copy_controller_file    
    template "external_id_handlers_controller.rb", "app/controllers/#{file_name.pluralize}_controller.rb"
  end

  def run_migration
    template "migrate_create_external_id_handler.rb", "db/migrate/#{Time.new.to_s(:number)}_create_#{file_name.pluralize}.rb"    
  end
  
  def copy_view_file
    template "_edit_form.html.erb", "app/views/#{file_name.pluralize}/_edit_form.html.erb"    
  end
  
  def copy_settings_file
    template "external_id_settings.rb", "config/initializers/external_id_#{singular_name}_settings.rb"
  end

  def copy_js_file
    template "_fpa_external_id.js", "app/assets/javascripts/external_id_#{plural_name}.js"
  end
    
  def append_to_routes
    line = "resources :scantrons, except: [:destroy]"
    gsub_file 'config/routes.rb', /(#{Regexp.escape(line)})/mi do |match|
      "#{match}\n    resources :#{plural_name}, except: [:destroy]\n"
    end
  end
  
end
