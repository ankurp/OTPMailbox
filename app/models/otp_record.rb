class OtpRecord < ApplicationRecord
  validates :recipient_email, presence: true
  validates :otp_code, presence: true
  validates :received_at, presence: true

  scope :for_email, ->(email) { where(recipient_email: email.downcase.strip) }
  scope :recent, -> { order(received_at: :desc) }

  before_validation :normalize_email

  private

  def normalize_email
    self.recipient_email = recipient_email&.downcase&.strip
  end
end
