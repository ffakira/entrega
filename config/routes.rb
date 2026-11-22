Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "menu", to: "menu#index", as: :menu

  resources :products, except: %i[show destroy] do
    patch :status, on: :member
    delete :remove_image, on: :member
  end

  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check
end
