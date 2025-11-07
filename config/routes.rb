Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :brands do
    scope module: :brand do
      resource :vision, only: [ :show, :update ], controller: :vision
      resource :logo, only: [ :show, :update ], controller: :logo
      resource :language, only: [ :show, :update ], controller: :language
      resource :colour_scheme, only: [ :show, :update ], controller: :colour_scheme
      resource :typography, only: [ :show, :update ], controller: :typography do
        collection do
          get :search_fonts
          get :suggest_fonts
          get :fonts_by_category
          patch :update_typeface
        end
      end
      resource :ui, only: [ :show, :update ], controller: :ui
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "brands#index"
end
