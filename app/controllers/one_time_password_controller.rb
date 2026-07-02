class OneTimePasswordController < ApplicationController
  include ActionController::Live

  skip_forgery_protection

  # How often an idle stream emits a keep-alive comment so the connection (and
  # any intermediary proxy) stays open while waiting for an OTP.
  STREAM_KEEPALIVE_INTERVAL = 20.seconds
  # Maximum time a single stream connection is held open before it closes and
  # lets the client reconnect. Keeps long-lived threads/connections bounded.
  STREAM_TIMEOUT = 5.minutes
  # Reconnection delay (ms) advertised to the browser's EventSource.
  STREAM_RETRY_MS = 3_000

  # GET /
  def home
  end

  # GET /otp/:username            → most recent OTP for username@<mail domain>
  # GET /otp/:username.json       → JSON response
  # Optional ?after=<ISO8601> returns the most recent OTP received strictly after that time.
  def show
    @email = email_for(params[:username])

    scope = OneTimePassword.for_email(@email).recent

    if params[:after].present?
      after_time = parse_time(params[:after])
      return render_error("Invalid 'after' timestamp", :bad_request) if after_time.nil?

      scope = scope.where("received_at > ?", after_time)
    end

    @one_time_password = scope.first

    return render_error("No OTP found for #{@email}", :not_found) if @one_time_password.nil?

    respond_to do |format|
      format.html
      format.json do
        render json: {
          email: @one_time_password.recipient_email,
          otp_code: @one_time_password.otp_code,
          subject: @one_time_password.subject,
          sender: @one_time_password.sender_email,
          received_at: @one_time_password.received_at.iso8601
        }
      end
    end
  end

  # GET /otp/:username/all        → 10 most recent OTPs for username@<mail domain>
  # GET /otp/:username/all.json   → JSON response
  def all
    @email = email_for(params[:username])

    @one_time_passwords = OneTimePassword.for_email(@email).recent.limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          email: @email,
          count: @one_time_passwords.size,
          otp_records: @one_time_passwords.map { |r|
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

  # GET /otp/:username/stream     → Server-Sent Events (SSE) stream
  #
  # Opens an event stream and delivers the next OTP for username@<mail domain>
  # as soon as its record is created, then closes the connection.
  #
  #
  # A browser's EventSource automatically reconnects after the server closes the
  # stream. We use the Last-Event-ID header to tell the two cases apart:
  #   * absent  → a fresh subscription: hold the stream open and wait for an OTP.
  #   * present → the automatic reconnect that follows a delivered OTP: there is
  #               nothing left to send, so respond 204 No Content, which tells
  #               EventSource to stop reconnecting.
  def stream
    # Automatic reconnect after we already delivered an OTP — stop the client.
    if request.headers["Last-Event-ID"].present?
      head :no_content
      return
    end

    email = email_for(params[:username])

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    # Disable proxy buffering so events reach the client immediately.
    response.headers["X-Accel-Buffering"] = "no"

    sse = SSE.new(response.stream, retry: STREAM_RETRY_MS)

    # Signalled by the callback once it has delivered an OTP and torn down the
    # subscription/stream, so the timeout path below knows it can stand down.
    done = Thread::Queue.new
    broadcasting = OneTimePassword.stream_name_for(email)

    # Runs on an Action Cable worker thread: write the OTP, tear down the
    # subscription/stream, then signal completion.
    callback = ->(message) do
      write_otp(sse, ActiveSupport::JSON.decode(message))
    rescue ActionController::Live::ClientDisconnected, IOError
      # Client went away mid-stream; fall through to teardown.
    ensure
      ActionCable.server.pubsub.unsubscribe(broadcasting, callback)
      sse.close
      done.push(true)
    end

    ActionCable.server.pubsub.subscribe(broadcasting, callback)

    # Block until the callback delivers an OTP. If none arrives before the
    # timeout, unsubscribe and close the stream ourselves; the client then
    # reconnects (no Last-Event-ID) and keeps waiting.
    return if done.pop(timeout: STREAM_TIMEOUT.to_f)

    ActionCable.server.pubsub.unsubscribe(broadcasting, callback)
    sse.close
  end

  private

  # Writes an OTP payload as a named SSE event, using the record id as the SSE
  # event id so the browser echoes it back via Last-Event-ID on reconnect.
  def write_otp(sse, payload)
    data = payload.symbolize_keys
    event_id = data.delete(:id)
    sse.write(data, event: "otp", id: event_id)
  end

  # Builds the full recipient email from a URL username segment. A bare
  # username (e.g. "john") is qualified with the configured mail domain;
  # an already-qualified address is used as-is.
  def email_for(username)
    local = username.to_s.downcase.strip
    local.include?("@") ? local : "#{local}@#{mail_domain}"
  end

  def mail_domain
    ENV.fetch("OTP_MAIL_DOMAIN", "otpinbox.dev")
  end

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
