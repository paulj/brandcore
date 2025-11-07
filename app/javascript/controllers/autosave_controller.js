import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.timeout = null
  }

  save() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce auto-save by 1 second
    this.timeout = setTimeout(() => {
      // Let Turbo handle the form submission - it will handle redirects, turbo-streams, etc.
      this.formTarget.requestSubmit()
    }, 1000)
  }
}
