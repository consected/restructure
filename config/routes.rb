# frozen_string_literal: true

Rails.application.routes.draw do
  # Provide Javascript testing in the browser, only in the development / test environment
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails) && (Rails.env.development? || Rails.env.test?)

  resources :page_layouts, only: %i[show index]

  resources :reports do
    member do
      post :add_to_list
      post :update_list
      post :remove_from_list
    end
  end

  resources :client_logs, only: [:create]

  resources :imports

  namespace :admin do
    resources :external_identifiers, except: %i[show destroy]
    resources :reports, except: %i[show destroy]
    resources :config_libraries, except: %i[show destroy]
    resources :external_identifier_details, except: [:destroy]
    resources :dynamic_models, except: %i[show destroy]
    resources :user_access_controls, except: %i[show destroy]
    resources :external_links, except: %i[show destroy]
    resources :colleges, except: %i[show destroy]
    resources :general_selections, except: %i[show destroy]
    resources :item_flag_names, except: %i[show destroy]
    resources :manage_users, except: %i[show destroy]
    resources :accuracy_scores, except: %i[show destroy]
    resources :activity_logs, except: %i[show destroy]
    resources :app_configurations, except: %i[show destroy]
    resources :message_templates, except: %i[show destroy]
    resources :message_notifications, except: %i[show destroy]
    resources :job_reviews, except: %i[show destroy]

    resources :app_types, except: [:destroy]
    post 'app_types/upload', to: 'app_types#upload'
    post 'app_types/restart_server', to: 'app_types#restart_server'

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

    namespace :nfs_store do
      namespace :filter do
        resources :filters, except: %i[show destroy]
      end
    end
  end

  namespace :users do
    resources :contact_infos, except: %i[show destroy]
  end

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

  ExternalIdentifier.routes_load
  ActivityLog.routes_load

  devise_for :admins, skip: [:registrations]
  devise_for :users, skip: [:registrations]

  devise_scope :admin do
    get '/admins/show_otp', to: 'devise/registrations#show_otp'
    post '/admins/test_otp', to: 'devise/registrations#test_otp'
  end

  devise_scope :user do
    get '/users/show_otp', to: 'devise/registrations#show_otp'
    post '/users/test_otp', to: 'devise/registrations#test_otp'
  end

  # mount NfsStore::Engine, at: "/nfs_store"
  namespace :nfs_store do
    resources :browse, only: :show
    resources :container_list, only: :show
    resources :chunk, only: %i[create show update]
    post 'downloads/multi', to: 'downloads#multi'
    resources :downloads, only: %i[show create]
    resources :classification, only: %i[edit create]
  end

  as :admin do
    get 'admins/edit' => 'devise/registrations#edit', :as => 'edit_admin_registration'
    put 'admins/:id' => 'devise/registrations#update', :as => 'admin_registration'
    root to: 'pages#index', as: 'authenticated_admin_root'
  end

  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users/:id' => 'devise/registrations#update', :as => 'user_registration'

    root to: 'masters#search', as: 'authenticated_user_root'
  end

  get 'child_error_reporter', to: 'application#child_error_reporter'

  root 'masters#search', as: 'guest_home'

  # Dynamic model goes at the end to avoid any issues with accidental clash of naming. The
  # dynamic model will only be applied if another item is not matched first
  DynamicModel.routes_load
end
