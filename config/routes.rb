Rails.application.routes.draw do
  namespace :admin do
    resources :users, only: [:index, :create, :destroy, :new] do
      member do
        delete :destroy
      end
    end
  end
  # Authentication routes
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"

  # Dashboard routes
  get "dashboard", to: "dashboard#index"
  get "admin_dashboard", to: "dashboard#admin"

  # Root route
  root "sessions#new"

  # Health check and PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
