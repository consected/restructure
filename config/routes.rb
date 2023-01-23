# frozen_string_literal: true

Rails.application.routes.draw do
  resources :page_layouts, only: %i[show index]
  get '/content/:id/:master_id/:secondary_key', to: 'page_layouts#show_content'
  get '/content/:id/:master_type/:master_id/:secondary_key', to: 'page_layouts#show_content'

  get '/help/:library/:section/images/:image_name', to: 'help#image', as: 'help_image'
  get '/help/:library/:section/:subsection', to: 'help#show', as: 'help_page', constraints: { subsection: /.+(\.md|\.jpg\.png)?/ }
  get '/help/:library/:section/:id', to: 'help#show', as: 'help', constraints: { id: /.+(\.md|\.jpg\.png)?/ }
  get '/help/:library', to: 'help#index', as: 'help_library_home'

  resources :help, only: %i[index]

  resources :reports do
    member do
      post :add_to_list
      post :update_list
      post :remove_from_list
    end
  end

  resources :client_logs, only: [:create]

  namespace :admin do
    resources :external_identifiers, except: %i[show destroy]
    get :external_identifier_details, to: 'external_identifiers#details'
    resources :reports, except: %i[show destroy]
    resources :config_libraries, except: %i[show destroy]
    resources :external_identifier_details, except: [:destroy]
    resources :dynamic_models, except: %i[show destroy] do
      member do
        post :update_config_from_table
      end
    end
    resources :user_access_controls, except: %i[show destroy]
    resources :external_links, except: %i[show destroy]
    resources :colleges, except: %i[show destroy]
    resources :general_selections, except: %i[show destroy]
    resources :item_flag_names, except: %i[show destroy]
    resources :manage_users, except: %i[show destroy]
    resources :manage_admins, except: %i[show destroy]
    resources :accuracy_scores, except: %i[show destroy]
    resources :activity_logs, except: %i[show destroy]
    resources :app_configurations, except: %i[show destroy]
    resources :message_templates, except: %i[show destroy]
    resources :message_notifications, except: %i[show destroy]
    resources :job_reviews, except: %i[show destroy]
    resources :server_info, only: [:index]
    get 'server_info/rails_log', to: 'server_info#rails_log'

    resources :app_types, except: [:destroy] do
      member do
        get :export_migrations
      end
    end
    post 'app_types/upload', to: 'app_types#upload'
    post 'app_types/restart_server', to: 'app_types#restart_server'
    post 'app_types/restart_delayed_job', to: 'app_types#restart_delayed_job'

    resources :role_descriptions, except: %i[show destroy]
    resources :user_roles, except: %i[show destroy]
    post 'user_roles/copy_user_roles', to: 'user_roles#copy_user_roles'
    resources :page_layouts, except: %i[show destroy]

    resources :protocols, except: %i[show destroy] do
      resources :sub_processes, except: %i[show destroy] do
        resources :protocol_events, except: %i[show destroy]
      end
    end
    resources :protocol_events, except: %i[show destroy]
    resources :sub_processes, except: %i[show destroy]

    get :reference_data, to: 'reference_data#index'
    resource :reference_data do
      member do
        get :table_list
        get :table_list_columns
        get :table_list_tables
        get :data_dic
      end
    end

    namespace :nfs_store do
      namespace :filter do
        resources :filters, except: %i[show destroy]
      end
    end
  end

  namespace :imports do
    resources :model_generators do
      member do
        post :analyze_csv
        post :create_model
      end
    end
    resources :model_generators, except: %i[destroy]
    resources :imports
  end

  namespace :redcap do
    resources :project_admins, except: %i[show destroy] do
      member do
        post :request_records
        post :request_archive
        post :request_users
        post :request_data_collection_instruments
        post :force_reconfig
        post :update_dynamic_model
      end
    end
    resources :data_dictionaries, except: %i[show destroy]
    resources :client_requests, except: %i[edit show destroy]

    resources :project_user_requests, except: %i[show destroy] do
      member do
        post :request_records
        post :request_archive
        post :request_users
      end
    end
  end

  namespace :users do
    resources :contact_infos, except: %i[show destroy]
  end

  get 'pages/home' => 'pages#home'
  get 'pages/app_home' => 'pages#app_home'
  resources :pages, only: %i[index show] do
    member do
      get :template
    end
  end

  # resources :pages, only: [:index, :show]

  post 'masters/create' => 'masters#create'
  post 'masters/' => 'masters#index'
  get 'masters/search', as: 'msid_search'
  get 'masters/search', as: 'masters_search'
  get 'masters/search' => 'masters#search'

  resources :definitions, only: %i[show create]

  resources :masters, only: %i[show index new create] do
    resources :tracker_histories, only: [:index]
    resources :player_infos, except: [:destroy]
    resources :player_contacts, except: [:destroy]
    resources :pro_infos, only: %i[show index], constraints: { id: /\d+/ }
    resources :addresses, except: [:destroy]

    resources :trackers, except: [:destroy] do
      resources :tracker_histories, only: [:index]
    end

    get ':item_controller/:item_id/item_flags/new', to: 'item_flags#new'
    get ':item_controller/:item_id/item_flags/', to: 'item_flags#index'
    get ':item_controller/:item_id/item_flags/:id', to: 'item_flags#show'
    post ':item_controller/:item_id/item_flags', to: 'item_flags#create'

    get ':item_controller/:item_id/model_references/:id/edit', to: 'model_references#edit'
    patch ':item_controller/:item_id/model_references/:id', to: 'model_references#update'

    get 'model_references/:id/edit', to: 'model_references#edit'
    patch 'model_references/:id', to: 'model_references#update'

    namespace :filestore do
      resources :classification
    end
  end

  resource :user_profile

  resources :user_preferences, only: %i[new create edit update show]

  ExternalIdentifier.routes_load
  ActivityLog.routes_load

  # BEGIN: Users and Admins related routes
  devise_for :admins, skip: [:registrations]

  if Settings::AllowUsersToRegister
    devise_for :users,
               only: %i[sessions confirmations passwords registrations],
               controllers: { registrations: 'users/registrations' }
  else
    devise_for :users,
               only: %i[sessions]
    as :user do
      get '/users/edit' => 'users/registrations#edit', as: :edit_user_registration
      put '/users' => 'users/registrations#update', as: :user_registration
    end
  end

  devise_scope :admin do
    get '/admins/show_otp', to: 'devise/registrations#show_otp'
    post '/admins/test_otp', to: 'devise/registrations#test_otp'
  end

  devise_scope :user do
    get '/users/show_otp', to: 'devise/registrations#show_otp'
    post '/users/test_otp', to: 'devise/registrations#test_otp'
  end

  as :admin do
    get 'admins/edit' => 'devise/registrations#edit', :as => 'edit_admin_registration'
    put 'admins/:id' => 'devise/registrations#update', :as => 'admin_registration'
    root to: 'pages#index', as: 'authenticated_admin_root'
  end

  as :user do
    root to: 'pages#home', as: 'authenticated_user_root'
  end

  # post 'mfa/step1', to: 'mfa#step1'
  resource :mfa, only: [] do
    member do
      post :step1, controller: :mfa, format: :json
    end
  end
  # END: Users and Admins related routes

  # mount NfsStore::Engine, at: "/nfs_store"
  namespace :nfs_store do
    resources :browse, only: :show
    resources :container_list, only: [:show] do
      member do
        get :content
      end
    end
    resources :chunk, only: %i[create show update]
    post 'downloads/multi', to: 'downloads#multi'
    get 'downloads/in/:activity_log_type/:activity_log_id/:download_path', to: 'downloads#show_from_activity_log',
                                                                           constraints: { download_path: /.*/ },
                                                                           format: false
    get 'downloads/search_doc/in/:activity_log_type/:activity_log_id/:download_path', to: 'downloads#search_doc_from_activity_log',
                                                                                      constraints: { download_path: /.*/ },
                                                                                      format: false
    #  ,
    #  defaults: { format: 'html' }
    resources :downloads, only: %i[show create] do
      member do
        get :search_doc
      end
    end
    resources :classification, only: %i[edit create]
  end

  get 'child_error_reporter', to: 'application#child_error_reporter'

  root 'pages#home', as: 'guest_home'

  # Dynamic model goes at the end to avoid any issues with accidental clash of naming. The
  # dynamic model will only be applied if another item is not matched first
  DynamicModel.routes_load

  match '*path', via: :all, to: 'bad_route#not_routed'
end
