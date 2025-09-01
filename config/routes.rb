Rails.application.routes.draw do
  # Subdomain constraints for company-specific routing
  constraints subdomain: /acme|techsolutions|globalsystems|default/ do
    namespace :admin do
      resources :users, only: [ :index, :create, :destroy, :new ] do
        member do
          delete :destroy
        end
      end
      resources :products do
        collection do
          get :upload
          post :import
        end
      end
      resources :categories, only: [ :index, :create, :destroy, :new ]
      resources :markets, only: [ :index, :create, :destroy, :new ]

      # AI models configuration
      get :ai_models, to: "ai_models#index"
      patch :ai_models, to: "ai_models#update"

      # Cost reports
      get :cost_reports, to: "cost_reports#index"
      get "cost_reports/user/:user_id", to: "cost_reports#user_details", as: :cost_reports_user
      get "cost_reports/export", to: "cost_reports#export"
    end

    # Authentication routes with subdomain
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    get "logout", to: "sessions#destroy"

    # Dashboard routes with subdomain
    get "dashboard", to: "dashboard#index"
    get "admin_dashboard", to: "dashboard#admin"

    # Product promotion routes
    resources :products, only: [] do
      member do
        get :promote, to: "promotions#show"
        post :promote, to: "promotions#create"
        post :regenerate, to: "promotions#regenerate"
        post :regenerate_images, to: "promotions#regenerate_images"
      end
    end

    # Root route for subdomains
    root "sessions#new", as: :company_root
  end

  # Default routes (no subdomain)
  get "companies", to: "companies#index"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"

  # Main root route - show company selection
  root "companies#index"

  # Debug route for subdomain testing
  get "debug/subdomain", to: "debug#subdomain_test"

  # Health check and PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
