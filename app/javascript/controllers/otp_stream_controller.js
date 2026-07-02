import { Controller } from "@hotwired/stimulus"

// Connects a small live demo on the homepage to the SSE endpoint
// (GET /otp/:username/stream). Opens an EventSource, renders the next OTP as
// soon as it arrives, then closes the stream.
//
//   data-controller="otp-stream"
//   data-otp-stream-target="username | toggle | status | log"
//   data-action="otp-stream#toggle"
export default class extends Controller {
  static targets = ["username", "toggle", "status", "log"]

  disconnect() {
    this.stop()
  }

  toggle() {
    this.source ? this.stop() : this.start()
  }

  start() {
    const username = this.usernameTarget.value.trim()
    if (!username) {
      this.setStatus("Enter a username first.")
      this.usernameTarget.focus()
      return
    }

    // Start fresh every time: clear any previous results and status.
    if (this.hasLogTarget) this.logTarget.replaceChildren()

    const address = `${username}@otpinbox.dev`
    const url = `/otp/${encodeURIComponent(username)}/stream`
    this.source = new EventSource(url)

    this.source.addEventListener("open", () => {
      this.setStatus(`Listening… send the full email to ${address}`)
    })

    this.source.addEventListener("otp", (event) => {
      this.renderOtp(JSON.parse(event.data))
      this.setStatus("OTP received — stream closed.")
      this.stop()
    })

    this.source.addEventListener("error", () => {
      // The browser reconnects automatically on a dropped connection; only
      // report if the stream is fully closed and we didn't get a code.
      if (this.source && this.source.readyState === EventSource.CLOSED) {
        this.setStatus("Connection closed.")
        this.stop()
      }
    })

    this.toggleTarget.textContent = "Stop"
    this.setStatus("Connecting…")
  }

  stop() {
    if (this.source) {
      this.source.close()
      this.source = null
    }
    if (this.hasToggleTarget) this.toggleTarget.textContent = "Listen"
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }

  // Builds the result node with textContent (never innerHTML) so OTP subjects
  // and sender addresses from untrusted email can't inject markup.
  renderOtp(otp) {
    const item = document.createElement("div")
    item.className = "stream-item"

    const code = document.createElement("div")
    code.className = "stream-code"
    code.textContent = otp.otp_code
    item.appendChild(code)

    const meta = document.createElement("div")
    meta.className = "stream-meta"
    meta.textContent = `${otp.subject || "(no subject)"} — from ${otp.sender || "unknown"} at ${this.formatTime(otp.received_at)}`
    item.appendChild(meta)

    this.logTarget.prepend(item)
  }

  // Converts an ISO 8601 timestamp (e.g. "2026-07-02T04:59:42Z") into the
  // viewer's local date and time. Falls back to the raw value if unparseable.
  formatTime(value) {
    if (!value) return "unknown time"
    const date = new Date(value)
    return isNaN(date) ? value : date.toLocaleString()
  }
}
