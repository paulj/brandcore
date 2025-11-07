import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "descriptionInput", "iconSelect", "list", "addButton"]
  static values = {
    values: Array,
    brandId: String
  }

  connect() {
    this.updateHiddenFields()
  }

  add(event) {
    event.preventDefault()

    const name = this.nameInputTarget.value.trim()
    const description = this.descriptionInputTarget.value.trim()
    const icon = this.iconSelectTarget.value

    if (name === "") {
      this.nameInputTarget.focus()
      return
    }

    // Create value object
    const newValue = {
      name: name,
      description: description,
      icon: icon
    }

    // Add to values array
    this.valuesValue = [...this.valuesValue, newValue]

    // Clear inputs
    this.nameInputTarget.value = ""
    this.descriptionInputTarget.value = ""
    this.iconSelectTarget.value = "fa-solid fa-heart"
    this.nameInputTarget.focus()

    // Update display and hidden fields
    this.renderValues()
    this.updateHiddenFields()
    this.saveValues()
  }

  remove(event) {
    event.preventDefault()

    const index = parseInt(event.currentTarget.dataset.index)

    // Remove from values array
    this.valuesValue = this.valuesValue.filter((_, i) => i !== index)

    // Update display and hidden fields
    this.renderValues()
    this.updateHiddenFields()
    this.saveValues()
  }

  renderValues() {
    // Clear existing values
    this.listTarget.innerHTML = ""

    // Render each value as a card
    this.valuesValue.forEach((value, index) => {
      const card = this.createValueCard(value, index)
      this.listTarget.appendChild(card)
    })

    // Add the "add new" form card
    const formCard = this.createFormCard()
    this.listTarget.appendChild(formCard)
  }

  createValueCard(value, index) {
    const div = document.createElement("div")
    div.className = "bg-white border-2 border-gray-200 rounded-lg p-6 flex items-start justify-between hover:border-gray-300 transition-colors"

    // Handle both old string format and new object format for backwards compatibility
    const name = typeof value === 'string' ? value : value.name
    const description = typeof value === 'string' ? '' : (value.description || '')
    const icon = typeof value === 'string' ? 'fa-solid fa-heart' : (value.icon || 'fa-solid fa-heart')

    div.innerHTML = `
      <div class="flex-1">
        <div class="flex items-start space-x-3">
          <div class="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
            <i class="${this.escapeHtml(icon)} text-gray-600"></i>
          </div>
          <div class="flex-1">
            <h4 class="text-gray-900 font-semibold mb-1">${this.escapeHtml(name)}</h4>
            ${description ? `<p class="text-gray-600 text-sm leading-relaxed">${this.escapeHtml(description)}</p>` : ''}
          </div>
        </div>
      </div>
      <button type="button"
              data-action="click->core-values#remove"
              data-index="${index}"
              class="text-gray-400 hover:text-red-500 transition-colors ml-4 flex-shrink-0">
        <i class="fa-solid fa-times"></i>
      </button>
    `

    return div
  }

  createFormCard() {
    const div = document.createElement("div")
    div.className = "border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-gray-400 transition-colors"

    div.innerHTML = `
      <div class="space-y-3">
        <div class="flex items-center space-x-2 mb-4">
          <i class="fa-solid fa-plus text-gray-400"></i>
          <span class="text-sm font-medium text-gray-600">Add Core Value</span>
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-700 mb-1">Icon</label>
          <select data-core-values-target="iconSelect"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent">
            <option value="fa-solid fa-heart">❤️ Heart</option>
            <option value="fa-solid fa-star">⭐ Star</option>
            <option value="fa-solid fa-shield">🛡️ Shield</option>
            <option value="fa-solid fa-lightbulb">💡 Lightbulb</option>
            <option value="fa-solid fa-rocket">🚀 Rocket</option>
            <option value="fa-solid fa-users">👥 Users</option>
            <option value="fa-solid fa-handshake">🤝 Handshake</option>
            <option value="fa-solid fa-trophy">🏆 Trophy</option>
            <option value="fa-solid fa-compass">🧭 Compass</option>
            <option value="fa-solid fa-gem">💎 Gem</option>
            <option value="fa-solid fa-bolt">⚡ Bolt</option>
            <option value="fa-solid fa-fire">🔥 Fire</option>
            <option value="fa-solid fa-leaf">🌿 Leaf</option>
            <option value="fa-solid fa-crown">👑 Crown</option>
            <option value="fa-solid fa-thumbs-up">👍 Thumbs Up</option>
            <option value="fa-solid fa-balance-scale">⚖️ Balance</option>
            <option value="fa-solid fa-brain">🧠 Brain</option>
            <option value="fa-solid fa-eye">👁️ Eye</option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-700 mb-1">Value Name *</label>
          <input type="text"
                 data-core-values-target="nameInput"
                 placeholder="e.g., Integrity, Innovation, Excellence..."
                 class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent">
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-700 mb-1">Description</label>
          <textarea data-core-values-target="descriptionInput"
                    placeholder="Explain what this value means to your brand..."
                    rows="3"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent resize-none"></textarea>
        </div>

        <button type="button"
                data-core-values-target="addButton"
                data-action="click->core-values#add"
                class="w-full bg-black hover:bg-gray-800 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
          Add Value
        </button>
      </div>
    `

    return div
  }

  updateHiddenFields() {
    // Remove existing hidden fields
    const existingFields = this.element.querySelectorAll('input[name^="brand_vision[core_values]"]')
    existingFields.forEach(field => field.remove())

    // Add hidden fields for each value as JSON
    this.valuesValue.forEach((value) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "brand_vision[core_values][]"
      input.value = JSON.stringify(value)
      this.element.appendChild(input)
    })
  }

  saveValues() {
    // Create FormData
    const formData = new FormData()

    this.valuesValue.forEach((value) => {
      formData.append("brand_vision[core_values][]", JSON.stringify(value))
    })

    // Get CSRF token
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    // Submit via fetch
    fetch(`/brands/${this.brandIdValue}/vision`, {
      method: 'PATCH',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error saving core values:', error)
    })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
