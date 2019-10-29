Rails.application.routes.draw do

  resources :page_layouts, only: [:show, :index]

  resources :reports do
    member do
      post :add_to_list
      post :remove_from_list
    end
  end

  resources :client_logs, only: [:create]

  resources :imports

  namespace :admin do
    resources :external_identifiers, except: [:show, :destroy]
    resources :reports, except: [:show, :destroy]
    resources :config_libraries, except: [:show, :destroy]
    resources :external_identifier_details, except: [:destroy]
    resources :dynamic_models, except: [:show, :destroy]
    resources :user_access_controls, except: [:show, :destroy]
    resources :external_links, except: [:show, :destroy]
    resources :colleges, except: [:show, :destroy]
    resources :general_selections, except: [:show, :destroy]
    resources :item_flag_names, except: [:show, :destroy]
    resources :manage_users, except: [:show, :destroy]
    resources :accuracy_scores, except: [:show, :destroy]
    resources :activity_logs, except: [:show, :destroy]
    resources :app_configurations, except: [:show, :destroy]
    resources :message_templates, except: [:show, :destroy]
    resources :message_notifications, except: [:show, :destroy]
    resources :job_reviews, except: [:show, :destroy]

    resources :app_types, except: [:destroy]
    post 'app_types/upload', to: 'app_types#upload'

    resources :user_roles, except: [:show, :destroy]
    post 'user_roles/copy_user_roles', to: 'user_roles#copy_user_roles'
    resources :page_layouts, except: [:show, :destroy]


    resources :protocols, except: [:show, :destroy] do
      resources :sub_processes, except: [:show, :destroy] do
        resources :protocol_events, except: [:show, :destroy]
      end

    end
    resources :protocol_events, except: [:show, :destroy]
    resources :sub_processes, except: [:show, :destroy]

    namespace :nfs_store do
      namespace :filter do
        resources :filters, except: [:show, :destroy]
      end
    end

  end

  namespace :users do
    resources :contact_infos, except: [:show, :destroy]
  end





  resources :pages, only: [:index, :show] do
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

  resources :definitions, only: [:show, :create]

  resources :masters, only: [:show, :index, :new, :create] do
    resources :tracker_histories, only: [:index]
    resources :player_infos, except: [:destroy]
    resources :player_contacts, except: [:destroy]
    resources :pro_infos, only: [:show, :index], constraints: { id: /\d+/ }
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

  devise_for :admins, :skip => [:registrations]
  devise_for :users, :skip => [:registrations]

  devise_scope :admin do
    get "/admins/show_otp", to: "devise/registrations#show_otp"
    post "/admins/test_otp", to: "devise/registrations#test_otp"
  end

  devise_scope :user do
    get "/users/show_otp", to: "devise/registrations#show_otp"
    post "/users/test_otp", to: "devise/registrations#test_otp"
  end

  #mount NfsStore::Engine, at: "/nfs_store"
  namespace :nfs_store do
    resources :browse, only: :show
    resources :container_list, only: :show
    resources :chunk, :only => [:create, :show, :update]
    post 'downloads/multi', to: 'downloads#multi'
    resources :downloads, :only => [:show, :create]
    resources :classification, only: [:edit, :create]
  end

  as :admin do
    get 'admins/edit' => 'devise/registrations#edit', :as => 'edit_admin_registration'
    put 'admins/:id' => 'devise/registrations#update', :as => 'admin_registration'
    root to: "pages#index", :as => "authenticated_admin_root"
  end


  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users/:id' => 'devise/registrations#update', :as => 'user_registration'

    root to: "masters#search", :as => "authenticated_user_root"
  end

  get "child_error_reporter", to: 'application#child_error_reporter'

  root "masters#search", :as=> 'guest_home'

  # Dynamic model goes at the end to avoid any issues with accidental clash of naming. The
  # dynamic model will only be applied if another item is not matched first
  DynamicModel.routes_load

end
