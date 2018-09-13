NfsStore::Engine.routes.draw do


  resources :browse, only: :show
  resources :container_list, only: :show
  resources :chunk, :only => [:create, :show]
  resources :downloads, :only => [:show, :create]
  resources :classification, only: [:edit, :create]


end
