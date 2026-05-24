require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  mount Sidekiq::Web => "/sidekiq"

  root to: "animes#index"
  resources :animes, only: [ :index, :show ]
  resources :songs, only: [ :show ]

  namespace :admin do
    root to: "animes#index"
    resources :animes, only: [ :index, :edit, :update ]
    resources :songs, only: [ :index, :new, :create, :edit, :update ] do
      member do
        patch :approve
        patch :reject
      end
    end
    resource :annict_sync, only: [ :new, :create ]
  end

  namespace :api do
    namespace :admin do
      resources :artists,      only: [ :index ]
      resources :animes,       only: [ :index ]
      resources :anime_series, only: [ :index ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
