class OtpInboundMailbox < ApplicationMailbox
  def process
    otp_code = extract_otp_code
    return unless otp_code

    OtpRecord.create!(
      recipient_email: recipient_email,
      otp_code: otp_code,
      subject: mail.subject,
      sender_email: mail.from&.first,
      received_at: mail.date || Time.current
    )

    Rails.logger.info "[OTPMailbox] Stored OTP #{otp_code} for #{recipient_email}"
  end

  private

  def recipient_email
    mail.to&.first&.downcase&.strip
  end

  def extract_otp_code
    # Try to extract OTP from the email body (plain text first, then HTML)
    text = mail.text_part&.decoded || decoded_body || ""

    # Common OTP patterns: 4-8 digit codes
    # Look for patterns like "code is 123456", "OTP: 123456", "verification code: 123456"
    patterns = [
      /(?:code|otp|pin|password|token|verify|verification)\s*(?:is|:|\s)\s*(\d{4,8})/i,
      /(\d{4,8})\s*(?:is your|is the)\s*(?:code|otp|pin|verification)/i,
      /\b(\d{6})\b/  # Fallback: standalone 6-digit number (most common OTP length)
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[1] if match
    end

    # Try HTML part if plain text didn't work
    if mail.html_part
      html_text = mail.html_part.decoded.gsub(/<[^>]+>/, " ")
      patterns.each do |pattern|
        match = html_text.match(pattern)
        return match[1] if match
      end
    end

    Rails.logger.warn "[OTPMailbox] No OTP code found in email to #{recipient_email}"
    nil
  end

  def decoded_body
    mail.body&.decoded
  rescue StandardError
    nil
  end
end
