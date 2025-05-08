Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'sessions#create', as: :user_login
      post 'sessions', to: 'sessions#create', as: :session_create
      get 'planilha', to: 'planilhas#show', as: :planilha
      delete 'sessions', to: 'sessions#destroy', as: :session_destroy
      get 'dashboard', to: 'dashboard#index', as: :dashboard
      get 'planilha', to: 'users#planilha', as: :planilhas
      resources :users do
        collection do
          post :login
        end
        member do
          post :unblock
        end
      end
      resources :planilhas, only: [:index]
      resources :trainings, only: [:index, :create]
      resources :meals, only: [:index, :create]
      resources :users, only: [:index, :create, :update, :destroy]
    end
  end
end