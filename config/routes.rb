Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  get "menu", to: "menu#index", as: :menu
  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check
end
