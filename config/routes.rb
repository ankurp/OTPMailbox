Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OTP endpoints — respond with HTML by default, or JSON when the
  # request path uses a .json extension (e.g. /otp/john.json).
  #   GET /otp/:username      → one_time_password#show  (most recent)
  #   GET /otp/:username/all  → one_time_password#all    (10 most recent)
  resources :otp, only: :show, param: :username, controller: "one_time_password" do
    get :all, on: :member
    get :stream, on: :member
  end

  # Homepage / docs
  root "one_time_password#home"
end
