import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "candidates", "textarea", "loading", "error"]
  static values = {
    url: String
  }

  connect() {
    this.generating = false
  }

  async generate() {
    if (this.generating) return

    this.generating = true
    this.showLoading()
    this.hideError()
    this.hideCandidates()

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.error || "Failed to generate mission statements")
      }

      const data = await response.json()
      this.displayCandidates(data.mission_statements)
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.hideLoading()
      this.generating = false
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      this.buttonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }

  displayCandidates(candidates) {
    if (!this.hasCandidatesTarget) return

    this.candidatesTarget.innerHTML = candidates.map((statement, index) => `
      <div class="border border-gray-200 rounded-lg p-4 hover:border-gray-400 hover:bg-gray-50 cursor-pointer transition-all group"
           data-action="click->mission-statement-ai#selectCandidate"
           data-statement="${this.escapeHtml(statement)}">
        <div class="flex items-start space-x-3">
          <div class="w-8 h-8 bg-gray-100 group-hover:bg-black group-hover:text-white rounded-lg flex items-center justify-center flex-shrink-0 transition-colors">
            <span class="text-sm font-semibold">${index + 1}</span>
          </div>
          <p class="text-gray-700 group-hover:text-gray-900 leading-relaxed flex-1">${this.escapeHtml(statement)}</p>
        </div>
      </div>
    `).join("")

    this.showCandidates()
  }

  showCandidates() {
    if (this.hasCandidatesTarget) {
      this.candidatesTarget.classList.remove("hidden")
    }
  }

  hideCandidates() {
    if (this.hasCandidatesTarget) {
      this.candidatesTarget.classList.add("hidden")
    }
  }

  selectCandidate(event) {
    const statement = event.currentTarget.dataset.statement
    if (!this.hasTextareaTarget) return

    this.textareaTarget.value = statement

    // Trigger input event to activate autosave
    this.textareaTarget.dispatchEvent(new Event("input", { bubbles: true }))

    this.hideCandidates()
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']").content
  }
}
