Rails.application.routes.draw do

  
    
  resources :action_logs
  
  resources :accuracy_scores
  
  resources :colleges
  resources :general_selections
  resources :item_flag_names
  
  resources :protocols do
    resources :sub_processes do
      resources :protocol_events
    end
    
  end
  
  resources :protocol_events
  resources :sub_processes
  
  
  get 'manage_users/home'
  resources :manage_users
  
  
  resources :pages, only: [:show, :index]
  
  post 'masters/create' => 'masters#create'
  post 'masters/' => 'masters#index'
  get 'masters/search', as: 'msid_search'
  get 'masters/search' => 'masters#search'
  resources :masters, only: [:show, :index, :new, :create] do
    resources :tracker_histories, only: [:index]
    resources :player_infos    
    resources :player_contacts
    resources :pro_infos
    resources :addresses
    resources :scantrons
    resources :trackers do
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
    root to: "masters#index", :as => "authenticated_root"
  end
  
  
  root "home#index", :as=> 'guest_home'
  
  
  
end
