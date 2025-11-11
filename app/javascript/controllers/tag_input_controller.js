import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "hiddenField"]
  static values = { fieldName: String }

  addTag(event) {
    event.preventDefault()
    const value = this.inputTarget.value.trim()

    if (value === "") return

    // Create tag element
    const tag = document.createElement("span")
    tag.className = "inline-flex items-center px-3 py-1 rounded-full text-sm bg-gray-100 text-gray-800"
    tag.innerHTML = `
      ${value}
      <button type="button" class="ml-2 text-gray-500 hover:text-gray-700" data-action="click->tag-input#removeTag">×</button>
    `

    // Create hidden input for form submission
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = this.fieldNameValue
    hiddenInput.value = value
    hiddenInput.dataset.tagInputTarget = "hiddenField"

    // Add to container
    this.containerTarget.appendChild(tag)

    // Add hidden field to form
    this.element.appendChild(hiddenInput)

    // Clear input
    this.inputTarget.value = ""

    // Trigger autosave if available
    this.triggerAutosave()
  }

  removeTag(event) {
    const tag = event.target.closest("span")
    const tagIndex = Array.from(this.containerTarget.children).indexOf(tag)

    // Remove tag element
    tag.remove()

    // Remove corresponding hidden field
    if (this.hasHiddenFieldTarget && this.hiddenFieldTargets[tagIndex]) {
      this.hiddenFieldTargets[tagIndex].remove()
    }

    // Trigger autosave if available
    this.triggerAutosave()
  }

  triggerAutosave() {
    const form = this.element.closest("form")
    if (form && form.dataset.controller && form.dataset.controller.includes("autosave")) {
      const autosaveController = this.application.getControllerForElementAndIdentifier(form, "autosave")
      if (autosaveController) {
        autosaveController.save()
      }
    }
  }
}
