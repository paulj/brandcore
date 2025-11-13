import { Controller } from "@hotwired/stimulus"

// Blurs the active element before form submission to prevent scroll issues,
// then refocuses the input after submission completes
export default class extends Controller {
  static targets = ["input"]

  submit(event) {
    // Blur the currently focused element (typically the input field)
    if (document.activeElement) {
      document.activeElement.blur()
    }
  }

  // Called after Turbo Stream response completes
  refocus(event) {
    if (event.detail.success && this.hasInputTarget) {
      // Small delay to ensure morph has completed
      setTimeout(() => {
        const input = this.element.querySelector('input[type="text"]')
        if (input) {
          input.focus()
        }
      }, 50)
    }
  }
}
