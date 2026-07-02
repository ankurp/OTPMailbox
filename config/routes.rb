Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OTP endpoints — respond with HTML by default, or JSON when the
  # request uses a .json extension (e.g. /otp.json).
  get "otp", to: "otp#show"       # Latest OTP for an email
  get "otp/all", to: "otp#index"  # All recent OTPs for an email

  # Homepage / docs
  root "otp#home"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
