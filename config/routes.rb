# config/routes.rb
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      
      get 'dashboard/current_user_profile', to: 'dashboard#current_user_profile'
      # Super Users
      post 'super_users', to: 'super_users#create'
      
      # Master Users
      resources :master_users, only: [:index, :create, :show, :update, :destroy]
      
      # ROTA ESPECÍFICA para buscar dados do master user atual
      get '/master_user', to: 'master_users#current_master'
      put '/master_user/:id', to: 'master_users#update'
      
      # Sessions
      post 'users/sign_in', to: 'sessions#create', as: :user_login
      post 'sessions', to: 'sessions#create', as: :session_create
      delete 'sessions', to: 'sessions#destroy', as: :session_destroy
      post 'login', to: 'sessions#create', as: :login
      
      # Dashboard - IMPORTANTE: Deve aceitar tanto Master quanto Super Users
      get 'dashboard', to: 'dashboard#index', as: :dashboard
      
      # Dashboard Settings
      resources :dashboard_settings, only: [:index, :show, :create, :update]
      
      # WhatsApp
      post 'send-whatsapp', to: 'whatsapp#send_message'
      
      # Current User - ADD THIS LINE
      get 'current_user', to: 'users#current_user', as: :current_user
      
      # Users
      resources :users do
        collection do
          # Remove current_user from here since it's now a standalone route
          post :unblock
          patch :recalculate_expiration
          patch :renew_plan
        end
        member do
          post :unblock
        end
      end
      
      # Other resources
      resources :planilhas, only: [:show]
      resources :trainings, only: [:index, :create]
      resources :meals, only: [:index, :create]
    end
  end
end