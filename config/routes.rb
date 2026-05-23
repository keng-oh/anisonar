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
    resources :songs, only: [ :index ] do
      member do
        patch :approve
        patch :reject
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
