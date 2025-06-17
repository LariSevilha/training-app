Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'sessions#create', as: :user_login
      post 'sessions', to: 'sessions#create', as: :session_create

      get 'planilha', to: 'planilhas#show', as: :planilha
      
      delete 'sessions', to: 'sessions#destroy', as: :session_destroy
      post 'login', to: 'sessions#create', as: :login

      resources :users do
        collection do
          post :unblock
        end
        member do
          post :unblock
        end
      end

      resources :planilhas, only: [:show] do
        collection do
          get :show, to: 'planilhas#show', as: :planilha
        end
      end

      resources :trainings, only: [:index, :create]
      resources :meals, only: [:index, :create]
      resources :users, only: [:index, :create, :update, :destroy]

      get 'dashboard', to: 'dashboard#index', as: :dashboard
    end
  end
end