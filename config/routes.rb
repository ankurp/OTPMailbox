Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OTP endpoints — respond with HTML by default, or JSON when the
  # request uses a .json extension (e.g. /otp.json).
  get "otp", to: "otp#show"       # Latest OTP for an email
  get "otp/all", to: "otp#index"  # All recent OTPs for an email

  # Homepage / docs
  root "otp#home"
end
