Rails.application.routes.draw do

  devise_for :users

  resources :container_list

  resources :users, only: [:update]

  namespace :admin do
    resources :user_roles
  end

  root to: 'container_list#index'

  mount NfsStore::Engine => "/nfs_store"
end
