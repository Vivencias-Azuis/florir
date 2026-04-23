Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "/auth/login",    to: "auth#login"
  post "/auth/register", to: "auth#register"

  resources :patients do
    resources :sessions, only: %i[index], controller: "therapy_sessions"
    resources :goals, only: %i[index], controller: "therapeutic_goals"
    resources :family_accesses, only: %i[index create destroy]
  end

  resources :therapy_sessions, only: %i[show create update destroy]
  resources :therapeutic_goals, only: %i[show create update destroy] do
    resources :progresses, only: %i[index create], controller: "goal_progresses"
  end

  resources :messages, only: %i[index create] do
    member { put :read }
  end

  namespace :family do
    get "/:token/dashboard", to: "portal#dashboard"
    get "/:token/sessions",  to: "portal#sessions"
    get "/:token/goals",     to: "portal#goals"
    post "/:token/messages", to: "portal#create_message"
    get "/:token/messages",  to: "portal#messages"
  end
end
