class OneTimePasswordController < ApplicationController
  skip_forgery_protection

  # GET /
  def home
  end

  # GET /otp/:username            → most recent OTP for username@<mail domain>
  # GET /otp/:username.json       → JSON response
  # Optional ?after=<ISO8601> returns the most recent OTP received strictly after that time.
  def show
    @email = email_for(params[:username])

    scope = OneTimePassword.for_email(@email).recent

    if params[:after].present?
      after_time = parse_time(params[:after])
      return render_error("Invalid 'after' timestamp", :bad_request) if after_time.nil?

      scope = scope.where("received_at > ?", after_time)
    end

    @one_time_password = scope.first

    return render_error("No OTP found for #{@email}", :not_found) if @one_time_password.nil?

    respond_to do |format|
      format.html
      format.json do
        render json: {
          email: @one_time_password.recipient_email,
          otp_code: @one_time_password.otp_code,
          subject: @one_time_password.subject,
          sender: @one_time_password.sender_email,
          received_at: @one_time_password.received_at.iso8601
        }
      end
    end
  end

  # GET /otp/:username/all        → 10 most recent OTPs for username@<mail domain>
  # GET /otp/:username/all.json   → JSON response
  def all
    @email = email_for(params[:username])

    @one_time_passwords = OneTimePassword.for_email(@email).recent.limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          email: @email,
          count: @one_time_passwords.size,
          otp_records: @one_time_passwords.map { |r|
            {
              otp_code: r.otp_code,
              subject: r.subject,
              sender: r.sender_email,
              received_at: r.received_at.iso8601
            }
          }
        }
      end
    end
  end

  private

  # Builds the full recipient email from a URL username segment. A bare
  # username (e.g. "john") is qualified with the configured mail domain;
  # an already-qualified address is used as-is.
  def email_for(username)
    local = username.to_s.downcase.strip
    local.include?("@") ? local : "#{local}@#{mail_domain}"
  end

  def mail_domain
    ENV.fetch("OTP_MAIL_DOMAIN", "otpinbox.dev")
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def render_error(message, status)
    @error = message

    respond_to do |format|
      format.html { render :error, status: status }
      format.json { render json: { error: message }, status: status }
    end
  end
end
