# Configure Action Mailbox ingress password
# Set ACTION_MAILBOX_INGRESS_PASSWORD environment variable in production
# or use Rails credentials: bin/rails credentials:edit
#
# For Exim/relay ingress, the URL is:
#   http://actionmailbox:PASSWORD@localhost/rails/action_mailbox/relay/inbound_emails
#
# For SendGrid ingress, the URL is:
#   https://actionmailbox:PASSWORD@yourdomain.com/rails/action_mailbox/sendgrid/inbound_emails
#
if ENV["ACTION_MAILBOX_INGRESS_PASSWORD"].present?
  Rails.application.config.action_mailbox.ingress_password = ENV["ACTION_MAILBOX_INGRESS_PASSWORD"]
end
