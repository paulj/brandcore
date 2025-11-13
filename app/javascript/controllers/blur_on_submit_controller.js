import { Controller } from "@hotwired/stimulus"

// Blurs the active element before form submission to prevent scroll issues
export default class extends Controller {
  submit(event) {
    // Blur the currently focused element (typically the input field)
    if (document.activeElement) {
      document.activeElement.blur()
    }
  }
}
