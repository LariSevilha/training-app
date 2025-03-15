Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  namespace :api do
    namespace :v1 do
      resources :user_types
      resources :users
      resources :meals
      resources :comidas
      resources :foods
      resources :amount_meals
      resources :series
      resources :repeats
      resources :exercises
      resources :trainings

        # Custom routes for user management
        get 'profile', to: 'users#profile', as: :user_profile
        post 'login', to: 'authentication#login', as: :login
        post 'register', to: 'authentication#register', as: :register
        get 'logout', to: 'authentication#logout', as: :logout
        
        # Training related custom routes
        get 'user/:user_id/trainings', to: 'trainings#user_trainings', as: :user_trainings
        get 'exercises/search/:keyword', to: 'exercises#search', as: :search_exercises
        get 'exercises/video/:id', to: 'exercises#video', as: :exercise_video
        
        # Meal and food related custom routes
        get 'user/:user_id/meals', to: 'meals#user_meals', as: :user_meals
        get 'meal-plans/weekly', to: 'meals#weekly_plan', as: :weekly_meal_plan
        get 'comidas/search/:keyword', to: 'comidas#search', as: :search_comidas
        
        # Dashboard and reports
        get 'dashboard/:user_id', to: 'dashboard#index', as: :dashboard
        get 'reports/progress/:user_id', to: 'reports#progress', as: :progress_report
        get 'reports/nutrition/:user_id', to: 'reports#nutrition', as: :nutrition_report
      end
    end
    end
  end
end
