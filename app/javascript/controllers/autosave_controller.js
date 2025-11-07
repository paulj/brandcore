import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.timeout = null
    this.saving = false
  }

  save() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce auto-save by 1 second
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, 1000)
  }

  submitForm() {
    if (this.saving) return

    this.saving = true
    const form = this.formTarget

    // Create FormData from the form
    const formData = new FormData(form)

    // Submit via fetch with Turbo Stream format
    fetch(form.action, {
      method: form.method,
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.text())
    .then(html => {
      // Turbo will automatically process the turbo-stream response
      Turbo.renderStreamMessage(html)
      this.saving = false
    })
    .catch(error => {
      console.error('Error saving:', error)
      this.saving = false
    })
  }
}
