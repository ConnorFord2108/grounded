Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :destinations, only: [:show] do
    resources :travel_plans, only: [:create, :new]
  end
  resources :travel_plans, only: [:index]
  post '/destinations', to: 'destinations#index'
end
