Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :slacks do
    resource :sl_command, only: [:create]
    resource :ir_message, only: [:create]
  end

  namespace :oauths do
    resource :landing, only: [:show]
    resource :register, only: [:show]
  end

  resource :kintai_status, only: [:create]
end
