module Api
  class OtpController < ApplicationController
    skip_forgery_protection

    # GET /api/otp?email=user@example.com
    def show
      email = params[:email]&.downcase&.strip

      if email.blank?
        render json: { error: "email parameter is required" }, status: :bad_request
        return
      end

      otp_record = OtpRecord.for_email(email).recent.first

      if otp_record
        render json: {
          email: otp_record.recipient_email,
          otp_code: otp_record.otp_code,
          subject: otp_record.subject,
          sender: otp_record.sender_email,
          received_at: otp_record.received_at.iso8601
        }
      else
        render json: { error: "No OTP found for #{email}" }, status: :not_found
      end
    end

    # GET /api/otp/all?email=user@example.com
    def index
      email = params[:email]&.downcase&.strip

      if email.blank?
        render json: { error: "email parameter is required" }, status: :bad_request
        return
      end

      otp_records = OtpRecord.for_email(email).recent.limit(10)

      render json: {
        email: email,
        count: otp_records.size,
        otp_records: otp_records.map { |r|
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
