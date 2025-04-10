Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, skip: :all

  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'sessions#create', as: :user_login
      get 'dashboard', to: 'dashboard#index', as: :dashboard
      post 'sessions', to: 'sessions#create', as: :session_create

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
 