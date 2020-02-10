Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resource :slack, only: [:create]
  namespace :oauth do
    resource :landing, only: [:show]
    resource :register, only: [:show]
  end
end
