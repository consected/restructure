Rails.application.routes.draw do

  
  resources :action_logs
  
  resources :accuracy_scores
  resources :protocol_outcomes
  resources :protocol_events
  resources :colleges
  resources :general_selections
  resources :item_flag_names
  resources :protocols
  devise_for :admins, :skip => [:registrations]
  devise_for :users, :skip => [:registrations]                                          

  
  get 'manage_users/home'
  resources :manage_users
  
  
  resources :pages, only: [:show, :index]
  
  post 'masters/create' => 'masters#create'
  post 'masters/' => 'masters#index'
  get 'masters/search', as: 'msid_search'
  get 'masters/search' => 'masters#search'
  resources :masters, only: [:show, :index, :new, :create] do
    resources :tracker_histories
    resources :player_infos    
    resources :player_contacts
    resources :pro_infos
    resources :manual_investigations
    resources :addresses
    resources :scantrons
    resources :trackers do
      resources :tracker_histories
    end
    
    get ':item_controller/:item_id/item_flags/new', to: 'item_flags#new'
    get ':item_controller/:item_id/item_flags/', to: 'item_flags#index'
    get ':item_controller/:item_id/item_flags/:id', to: 'item_flags#show'
    get ':item_controller/:item_id/item_flags/:id/edit', to: 'item_flags#edit'
    patch ':item_controller/:item_id/item_flags/:id', to: 'item_flags#update'
    post ':item_controller/:item_id/item_flags/:id', to: 'item_flags#create'

  end
  
  
  
#  get 'masters/index'
#  get 'masters/show'

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
  
  
  
  #root "home#index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
