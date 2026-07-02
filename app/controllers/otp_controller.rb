class OtpController < ApplicationController
  skip_forgery_protection

  # GET /
  def home
  end

  # GET /otp?email=user@example.com&after=2026-07-01T12:00:00Z
  # GET /otp.json?email=user@example.com  (JSON response)
  def show
    @email = params[:email]&.downcase&.strip

    return render_error("email parameter is required", :bad_request) if @email.blank?

    scope = OtpRecord.for_email(@email).recent

    if params[:after].present?
      after_time = parse_time(params[:after])
      return render_error("Invalid 'after' timestamp", :bad_request) if after_time.nil?

      scope = scope.where("received_at > ?", after_time)
    end

    @otp_record = scope.first

    return render_error("No OTP found for #{@email}", :not_found) if @otp_record.nil?

    respond_to do |format|
      format.html
      format.json do
        render json: {
          email: @otp_record.recipient_email,
          otp_code: @otp_record.otp_code,
          subject: @otp_record.subject,
          sender: @otp_record.sender_email,
          received_at: @otp_record.received_at.iso8601
        }
      end
    end
  end

  # GET /otp/all?email=user@example.com
  # GET /otp/all.json?email=user@example.com  (JSON response)
  def index
    @email = params[:email]&.downcase&.strip

    return render_error("email parameter is required", :bad_request) if @email.blank?

    @otp_records = OtpRecord.for_email(@email).recent.limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          email: @email,
          count: @otp_records.size,
          otp_records: @otp_records.map { |r|
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
