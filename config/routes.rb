Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'sessions#create', as: :user_login
      get '/master_user', to: 'master_users#show'
      put '/master_user/:id', to: 'master_users#update'
      resources :dashboard_settings, only: [:index, :show, :create, :update]
      post 'sessions', to: 'sessions#create', as: :session_create
      delete 'sessions', to: 'sessions#destroy', as: :session_destroy
      post 'login', to: 'sessions#create', as: :login
      post 'send-whatsapp', to: 'whatsapp#send_message'
      get 'current_user', to: 'users#current_user'

      resources :users do
        collection do
          get :current_user
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
      resources :users, only: [:index, :create, :update, :destroy]
      get 'dashboard', to: 'dashboard#index', as: :dashboard
    end
  end
end