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
# Action Mailbox reads the ingress password from Rails credentials
# (action_mailbox.ingress_password) or the RAILS_INBOUND_EMAIL_PASSWORD
# environment variable. We accept a single ACTION_MAILBOX_INGRESS_PASSWORD
# env var and map it to what Action Mailbox expects.
if ENV["ACTION_MAILBOX_INGRESS_PASSWORD"].present?
  ENV["RAILS_INBOUND_EMAIL_PASSWORD"] ||= ENV["ACTION_MAILBOX_INGRESS_PASSWORD"]
end
