require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  mount Sidekiq::Web => "/sidekiq"

  root to: "animes#index"
  resources :animes, only: [ :index, :show ]
  resources :anime_series, only: [ :show ]

  namespace :admin do
    root to: "dashboard#index"
    resources :animes, only: [ :index, :edit, :update ] do
      collection do
        post :bulk_cover_image_resolve
      end
      member do
        post :enqueue_crawl_request
      end
    end
    resources :songs, only: [ :index, :new, :create, :edit, :update ] do
      collection do
        post :bulk_spotify_resolve
        get :all
      end
      member do
        patch :approve
        patch :reject
      end
    end
    resources :integrations, only: [] do
      collection do
        get :cover_images
        get :spotify
        get :crawl_requests
        get :annict_sync
        post "annict_sync", to: "integrations#create_annict_sync", as: :create_annict_sync
      end
    end
  end

  namespace :api do
    namespace :admin do
      resources :artists,      only: [ :index ]
      resources :animes,       only: [ :index ]
      resources :anime_series, only: [ :index ]
    end

    namespace :n8n do
      resources :crawl_requests, only: [ :index, :update ] do
        member do
          post :songs
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
