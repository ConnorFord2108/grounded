Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :destinations, only: [:show] do
    resources :travel_plans, only: [:create, :new]
  end

  resources :travel_plans, only: [:index, :destroy, :update] do
    resources :reviews, only: [:create]
  end
  # post '/destinations', to: 'destinations#index'
  get '/destinations', to: 'destinations#index', as: :destinations
  post '/travel_plans', to: 'travel_plans#index'
  # post '/destinations/:search_term&:max_travel_hours', to: 'destinations#index'

  # require "sidekiq/web"
  # authenticate :user, ->(user) { user.admin? } do
  #   mount Sidekiq::Web => '/sidekiq'
  # end
end
