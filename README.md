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

### Stream the Next OTP (Server-Sent Events)

```
GET /otp/john/stream
```

Opens a [Server-Sent Events](https://developer.mozilla.org/docs/Web/API/Server-sent_events) stream that stays open and pushes the **next** OTP for `john@otpinbox.dev` the moment it arrives, then closes the connection. Delivery is push-based (Action Cable pub/sub) — there is no polling.

The event is named `otp` and its `id` is the OTP record id:

```
event: otp
id: 42
data: {"email":"john@otpinbox.dev","otp_code":"123456","subject":"Your verification code","sender":"noreply@service.com","received_at":"2024-01-15T10:30:00Z"}
```

**Reconnect behaviour:** after an OTP is delivered the server closes the stream. A browser's `EventSource` automatically reconnects, sending the `Last-Event-ID` header; the server treats that reconnect as "already delivered" and responds `204 No Content`, which stops `EventSource` from reconnecting. A fresh connection (no `Last-Event-ID`) waits for the next OTP. If none arrives within 5 minutes the connection closes and the client reconnects to keep waiting.

**Browser:**
```js
const source = new EventSource("/otp/john/stream");
source.addEventListener("otp", (event) => {
  const otp = JSON.parse(event.data);
  console.log("Code:", otp.otp_code);
  source.close();
});
```

**cURL:**
```bash
curl -N https://yourdomain.com/otp/john/stream
```

### Error Responses

- `400` - Invalid `after` timestamp
- `404` - No OTP found for the given user

## Development

Use the Action Mailbox conductor UI in development to test incoming emails:
```
http://localhost:3000/rails/conductor/action_mailbox/inbound_emails
```
