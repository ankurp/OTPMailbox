# OTP Inbox

A Rails app that receives all incoming emails via SendGrid's Inbound Parse webhook, extracts OTP codes, and exposes a simple API to retrieve them.

## How It Works

1. **SendGrid Inbound Parse** forwards all incoming emails to this app
2. **Action Mailbox** receives the email via the SendGrid ingress
3. **OtpMailbox** parses the email body and extracts OTP codes (4-8 digit codes)
4. **API** lets you query the latest OTP for any email address

## Setup

### Prerequisites

- Ruby 3.3.9
- Rails 8.1

### Install & Run

```bash
bundle install
bin/rails db:migrate
bin/rails server
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `ACTION_MAILBOX_INGRESS_PASSWORD` | Password for authenticating SendGrid webhook requests |

### Configure SendGrid Inbound Parse

1. Go to SendGrid → Settings → Inbound Parse
2. Add your domain/subdomain (e.g., `otp.yourdomain.com`)
3. Set the webhook URL to:
   ```
   https://actionmailbox:YOUR_PASSWORD@yourdomain.com/rails/action_mailbox/sendgrid/inbound_emails
   ```
4. Check "POST the raw, full MIME message"

### MX Record

Point your domain's MX record to SendGrid:
```
MX  otp.yourdomain.com  mx.sendgrid.net  (priority 10)
```

## Endpoints

Each endpoint returns an HTML page by default. Append a `.json` extension to the path to get a JSON response instead.

### Get Latest OTP

```
GET /otp/john
GET /otp/john.json                             # JSON response
GET /otp/john.json?after=2024-01-15T10:30:00Z  # most recent after a time
```

**JSON Response:**
```json
{
  "email": "john@otpinbox.dev",
  "otp_code": "123456",
  "subject": "Your verification code",
  "sender": "noreply@service.com",
  "received_at": "2024-01-15T10:30:00Z"
}
```

### Get All Recent OTPs

```
GET /otp/john/all
GET /otp/john/all.json                         # JSON response
```

**JSON Response:**
```json
{
  "email": "john@otpinbox.dev",
  "count": 2,
  "otp_records": [
    {
      "otp_code": "123456",
      "subject": "Your verification code",
      "sender": "noreply@service.com",
      "received_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Error Responses

- `400` - Invalid `after` timestamp
- `404` - No OTP found for the given user

## Development

Use the Action Mailbox conductor UI in development to test incoming emails:
```
http://localhost:3000/rails/conductor/action_mailbox/inbound_emails
```
