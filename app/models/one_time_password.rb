class OneTimePassword < ApplicationRecord
  validates :recipient_email, presence: true
  validates :otp_code, presence: true
  validates :received_at, presence: true

  scope :for_email, ->(email) { where(recipient_email: email.downcase.strip) }
  scope :recent, -> { order(received_at: :desc) }

  before_validation :normalize_email
  after_create_commit :broadcast_arrival

  # Action Cable broadcasting name that SSE subscribers listen on for a given
  # recipient address.
  def self.stream_name_for(email)
    "otp:#{email.to_s.downcase.strip}"
  end

  # Payload delivered both over the SSE stream and the pub/sub broadcast.
  def stream_payload
    {
      id: id,
      email: recipient_email,
      otp_code: otp_code,
      subject: subject,
      sender: sender_email,
      received_at: received_at.iso8601
    }
  end

  private

  def normalize_email
    self.recipient_email = recipient_email&.downcase&.strip
  end

  # Notify any open SSE stream waiting for this recipient. Runs after commit so
  # the record is durable and visible before subscribers react.
  def broadcast_arrival
    ActionCable.server.broadcast(self.class.stream_name_for(recipient_email), stream_payload)
  end
end
