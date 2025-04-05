Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :sessions, only: [:create] do
        delete 'logout', on: :collection
      end
      resources :dashboard, only: [:index]
      resources :users
      resources :trainings, only: [:index, :create]
      resources :meals, only: [:index, :create]
    end
  end
end