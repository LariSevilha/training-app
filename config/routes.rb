Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'dashboard/current_user_profile', to: 'dashboard#current_user_profile'
      put 'dashboard/update_current_user', to: 'dashboard#update_current_user' # Add this
      put 'dashboard/change_password', to: 'dashboard#change_password' # Add this
      post 'super_users', to: 'super_users#create'
      resources :master_users, only: [:index, :create, :show, :update, :destroy]
      get '/master_user', to: 'master_users#current_master'
      put '/master_user/:id', to: 'master_users#update'
      post 'users/sign_in', to: 'sessions#create', as: :user_login
      post 'sessions', to: 'sessions#create', as: :session_create
      delete 'sessions', to: 'sessions#destroy', as: :session_destroy
      post 'login', to: 'sessions#create', as: :login
      get 'dashboard', to: 'dashboard#index', as: :dashboard
      resources :dashboard_settings, only: [:index, :show, :create, :update]
      post 'send-whatsapp', to: 'whatsapp#send_message'
      get 'current_user', to: 'users#current_user', as: :current_user
      resources :users do
        collection do
          post :unblock
          patch :recalculate_expiration
          patch :renew_plan
        end
        member do
          post :unblock
        end
      end
      resources :planilhas, only: [:show]
      resources :trainings, only: [:index, :create]
      resources :meals, only: [:index, :create]
    end
  end
end