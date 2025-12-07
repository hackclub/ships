Rails.application.routes.draw do
  get "/dash", to: "dashboard#index", as: :dash
  get "/stats", to: "stats#index", as: :stats
  get "/docs", to: "docs#index", as: :docs
  post "/entries/:id/fetch_stars", to: "ysws_entries#fetch_stars", as: :fetch_stars
  get "/entries/:id/virality", to: "ysws_entries#fetch_virality", as: :fetch_virality
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # OmniAuth routes (POST handled by OmniAuth middleware)
  post "/auth/:provider", to: lambda { |_| [ 404, {}, [ "Not Found" ] ] }
  get "/oauth/callback", to: "sessions#create"
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy"

  # Admin-only routes
  admin_constraint = ->(request) {
    user_id = request.session[:user_id]
    user_id && User.find_by(id: user_id)&.admin?
  }

  constraints admin_constraint do
    get "/admin", to: "admin#index", as: :admin
    get "/admin/users", to: "admin#users", as: :admin_users
    post "/admin/impersonate/:id", to: "admin#impersonate", as: :admin_impersonate
    post "/admin/impersonate_by_email", to: "admin#impersonate_by_email", as: :admin_impersonate_by_email
    delete "/admin/stop_impersonating", to: "admin#stop_impersonating", as: :admin_stop_impersonating
    mount Flipper::UI.app(Flipper) => "/flipper"
    mount Blazer::Engine => "/blazer"
    mount Audits1984::Engine => "/console"
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API routes
  namespace :api do
    namespace :v1 do
      resources :ysws_entries, only: [ :index ]
      resources :me, only: [ :index ]
      resources :cached_images, only: [ :show ]
      resources :stats, only: [ :index ]
      resources :dashboard, only: [ :index ]

      namespace :admin do
        get "users", to: "admin#users"
        get "entries", to: "admin#entries"
        get "stats", to: "admin#stats"
      end
    end
  end

  # Defines the root path route ("/")
  root "home#index"
end
