class ApplicationMailbox < ActionMailbox::Base
  # Route all incoming emails to the OTP mailbox
  routing all: :otp_inbound
end
