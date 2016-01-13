Rails.application.routes.draw do
  
  resources :reports
  namespace :admin do
    resources :reports, except: [:show, :destroy]
    resources :sage_assignments, except: [:destroy]
    resources :dynamic_models, except: [:show, :destroy]
    resources :user_authorizations, except: [:show, :destroy]
    resources :external_links, except: [:show, :destroy]
    resources :colleges, except: [:show, :destroy]
    resources :general_selections, except: [:show, :destroy]  
    resources :item_flag_names, except: [:show, :destroy]
    resources :manage_users, except: [:show, :destroy]
    resources :accuracy_scores, except: [:show, :destroy]  
    resources :action_logs, only: [:show, :index]
  end
    
  




  
  
  resources :protocols, except: [:show, :destroy] do
    resources :sub_processes, except: [:show, :destroy] do
      resources :protocol_events, except: [:show, :destroy]
    end
    
  end
  
  resources :protocol_events, except: [:show, :destroy]
  resources :sub_processes, except: [:show, :destroy]  

  
  
  resources :pages, only: [:index]
  
  post 'masters/create' => 'masters#create'
  post 'masters/' => 'masters#index'
  get 'masters/search', as: 'msid_search'
  get 'masters/search' => 'masters#search'
  
  resources :definitions, only: [:show]
  
  resources :masters, only: [:show, :index, :new, :create] do
    resources :tracker_histories, only: [:index]
    resources :player_infos, except: [:destroy]    
    resources :player_contacts, except: [:destroy]
    resources :pro_infos, only: [:show, :index], constraints: { id: /\d+/ }    
    resources :addresses, except: [:destroy]
    resources :scantrons, except: [:destroy]


    resources :sage_assignments, except: [:destroy]
    resources :trackers, except: [:destroy] do
      resources :tracker_histories, only: [:index]
    end
    
    get ':item_controller/:item_id/item_flags/new', to: 'item_flags#new'
    get ':item_controller/:item_id/item_flags/', to: 'item_flags#index'
    get ':item_controller/:item_id/item_flags/:id', to: 'item_flags#show'
    post ':item_controller/:item_id/item_flags', to: 'item_flags#create'

    get 'dynamic_model/:item_controller/:item_id/item_flags/new', to: 'item_flags#new'
    get 'dynamic_model/:item_controller/:item_id/item_flags/', to: 'item_flags#index'
    get 'dynamic_model/:item_controller/:item_id/item_flags/:id', to: 'item_flags#show'
    post 'dynamic_model/:item_controller/:item_id/item_flags', to: 'item_flags#create'
    
    
  end
  
  devise_for :admins, :skip => [:registrations]
  devise_for :users, :skip => [:registrations]                                          

    
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
  
  root "masters#search", :as=> 'guest_home'
  DynamicModel.routes_load    
  
end
