Rails.application.routes.draw do

  
    
  resources :action_logs, only: [:show, :index]
  
  resources :accuracy_scores, except: [:destroy]
  
  resources :colleges, except: [:destroy]
  resources :general_selections, except: [:destroy]
  resources :item_flag_names, except: [:destroy]
  
  resources :protocols, except: [:destroy] do
    resources :sub_processes, except: [:destroy] do
      resources :protocol_events, except: [:destroy]
    end
    
  end
  
  resources :protocol_events, except: [:destroy]
  resources :sub_processes, except: [:destroy]
  
  
  get 'manage_users/home'
  resources :manage_users, except: [:destroy]
  
  
  resources :pages, only: [:index]
  
  post 'masters/create' => 'masters#create'
  post 'masters/' => 'masters#index'
  get 'masters/search', as: 'msid_search'
  get 'masters/search' => 'masters#search'
  resources :masters, only: [:show, :index, :new, :create] do
    resources :tracker_histories, only: [:index]
    resources :player_infos, except: [:destroy]    
    resources :player_contacts, except: [:destroy]
    resources :pro_infos, only: [:show, :index]    
    resources :addresses, except: [:destroy]
    resources :scantrons, except: [:destroy]
    resources :trackers, except: [:destroy] do
      resources :tracker_histories, only: [:index]
    end
    
    get ':item_controller/:item_id/item_flags/new', to: 'item_flags#new'
    get ':item_controller/:item_id/item_flags/', to: 'item_flags#index'
    get ':item_controller/:item_id/item_flags/:id', to: 'item_flags#show'
    post ':item_controller/:item_id/item_flags/:id', to: 'item_flags#create'

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
  
  
  
end
