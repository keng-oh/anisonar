require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  mount Sidekiq::Web => "/sidekiq"

  root to: "animes#index"
  resources :animes, only: [ :index, :show ]
  resources :anime_series, only: [ :show ]

  namespace :admin do
    root to: "animes#index"
    resources :animes, only: [ :index, :edit, :update ] do
      collection do
        post :bulk_ai_song_research
        post :bulk_cover_image_resolve
      end
      member do
        post :ai_song_research
      end
    end
    resources :songs, only: [ :index, :new, :create, :edit, :update ] do
      collection do
        post :bulk_spotify_resolve
      end
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
