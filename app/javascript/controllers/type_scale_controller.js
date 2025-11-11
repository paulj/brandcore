import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "fontSizeInput", "lineHeightInput", "variantInput", "fontWeightInput", "addButton"]
  static values = {
    scales: Array,
    typefaceId: String,
    brandId: String,
    fontFamily: String,
    variants: Array
  }

  connect() {
    this.populateFontWeightOptions()
    this.updateHiddenFields()
  }

  populateFontWeightOptions() {
    if (!this.hasFontWeightInputTarget) return
    
    const variants = this.variantsValue || []
    const fontWeightSelect = this.fontWeightInputTarget
    
    // Clear existing options
    fontWeightSelect.innerHTML = ""
    
    // Extract unique font weights from variants
    // Google Fonts variants are like "100", "300", "400", "400italic", "700", "700italic", etc.
    const weights = new Set()
    
    variants.forEach(variant => {
      // Extract numeric weight (remove "italic" suffix if present)
      const weight = variant.toString().replace(/italic$/i, "")
      if (/^\d+$/.test(weight)) {
        weights.add(weight)
      }
    })
    
    // If no variants available, use default weights
    if (weights.size === 0) {
      weights.add("100")
      weights.add("300")
      weights.add("400")
      weights.add("500")
      weights.add("600")
      weights.add("700")
      weights.add("800")
      weights.add("900")
    }
    
    // Sort weights numerically and create options
    const sortedWeights = Array.from(weights).sort((a, b) => parseInt(a) - parseInt(b))
    
    sortedWeights.forEach(weight => {
      const option = document.createElement("option")
      option.value = weight
      option.textContent = `${weight}${this.getWeightLabel(weight)}`
      fontWeightSelect.appendChild(option)
    })
    
    // Set default to 400 if available
    if (sortedWeights.includes("400")) {
      fontWeightSelect.value = "400"
    } else if (sortedWeights.length > 0) {
      fontWeightSelect.value = sortedWeights[0]
    }
  }

  getWeightLabel(weight) {
    const labels = {
      "100": " (Thin)",
      "200": " (Extra Light)",
      "300": " (Light)",
      "400": " (Regular)",
      "500": " (Medium)",
      "600": " (Semi Bold)",
      "700": " (Bold)",
      "800": " (Extra Bold)",
      "900": " (Black)"
    }
    return labels[weight] || ""
  }

  add(event) {
    event.preventDefault()

    const fontSize = this.fontSizeInputTarget.value.trim()
    const lineHeight = this.lineHeightInputTarget.value.trim()
    const variant = this.variantInputTarget.value.trim()
    const fontWeight = this.fontWeightInputTarget.value.trim() || "400"

    if (fontSize === "" || lineHeight === "") {
      if (fontSize === "") {
        this.fontSizeInputTarget.focus()
      } else {
        this.lineHeightInputTarget.focus()
      }
      return
    }

    // Create scale object
    const newScale = {
      font_size: fontSize,
      line_height: lineHeight,
      variant: variant || "Regular",
      font_weight: fontWeight
    }

    // Add to scales array
    this.scalesValue = [...this.scalesValue, newScale]

    // Clear inputs
    this.fontSizeInputTarget.value = ""
    this.lineHeightInputTarget.value = ""
    this.variantInputTarget.value = "Regular"
    if (this.hasFontWeightInputTarget) {
      // Reset to default weight
      const defaultWeight = this.fontWeightInputTarget.querySelector('option[value="400"]') ? "400" : this.fontWeightInputTarget.options[0]?.value || "400"
      this.fontWeightInputTarget.value = defaultWeight
    }
    this.fontSizeInputTarget.focus()

    // Update display and hidden fields
    this.renderTable()
    this.updateHiddenFields()
    this.saveScales()
  }

  remove(event) {
    event.preventDefault()

    const index = parseInt(event.currentTarget.dataset.index)

    // Remove from scales array
    this.scalesValue = this.scalesValue.filter((_, i) => i !== index)

    // Update display and hidden fields
    this.renderTable()
    this.updateHiddenFields()
    this.saveScales()
  }

  renderTable() {
    // Get tbody and preserve form row
    const tbody = this.tableTarget.querySelector("tbody")
    const formRow = tbody.querySelector("tr[data-type-scale-target='formRow']")
    
    // Clear existing rows (except form row)
    const existingRows = tbody.querySelectorAll("tr:not([data-type-scale-target='formRow'])")
    existingRows.forEach(row => row.remove())

    // Render each scale as a table row (before the form row)
    this.scalesValue.forEach((scale, index) => {
      const row = this.createScaleRow(scale, index)
      if (formRow) {
        tbody.insertBefore(row, formRow)
      } else {
        tbody.appendChild(row)
      }
    })

    // Add the form row at the bottom if it doesn't exist
    if (!formRow) {
      const newFormRow = this.createFormRow()
      tbody.appendChild(newFormRow)
    }
  }

  createScaleRow(scale, index) {
    const tr = document.createElement("tr")
    tr.className = "border-b border-gray-200 hover:bg-gray-50"

    const fontFamily = this.fontFamilyValue || "sans-serif"
    const fontSize = scale.font_size || ""
    const lineHeight = scale.line_height || ""
    const variant = scale.variant || "Regular"
    const fontWeight = scale.font_weight || "400"

    tr.innerHTML = `
      <td class="px-4 py-3">
        <span style="font-family: '${this.escapeHtml(fontFamily)}', sans-serif; font-size: ${this.escapeHtml(fontSize)}; line-height: ${this.escapeHtml(lineHeight)}; font-weight: ${this.escapeHtml(fontWeight)};">
          Sample Text
        </span>
      </td>
      <td class="px-4 py-3 text-sm text-gray-600">${this.escapeHtml(fontSize)}</td>
      <td class="px-4 py-3 text-sm text-gray-600">${this.escapeHtml(lineHeight)}</td>
      <td class="px-4 py-3 text-sm text-gray-600 capitalize">${this.escapeHtml(variant)}</td>
      <td class="px-4 py-3 text-sm text-gray-600">${this.escapeHtml(fontWeight)}</td>
      <td class="px-4 py-3">
        <button type="button"
                data-action="click->type-scale#remove"
                data-index="${index}"
                class="text-gray-400 hover:text-red-500 transition-colors">
          <i class="fa-solid fa-times"></i>
        </button>
      </td>
    `

    return tr
  }

  createFormRow() {
    const tr = document.createElement("tr")
    tr.setAttribute("data-type-scale-target", "formRow")
    tr.className = "bg-gray-50"

    // Build font weight options HTML
    const variants = this.variantsValue || []
    const weights = new Set()
    variants.forEach(variant => {
      const weight = variant.toString().replace(/italic$/i, "")
      if (/^\d+$/.test(weight)) {
        weights.add(weight)
      }
    })
    
    if (weights.size === 0) {
      weights.add("100")
      weights.add("300")
      weights.add("400")
      weights.add("500")
      weights.add("600")
      weights.add("700")
      weights.add("800")
      weights.add("900")
    }
    
    const sortedWeights = Array.from(weights).sort((a, b) => parseInt(a) - parseInt(b))
    const fontWeightOptions = sortedWeights.map(weight => 
      `<option value="${weight}">${weight}${this.getWeightLabel(weight)}</option>`
    ).join("")

    tr.innerHTML = `
      <td class="px-4 py-3" colspan="6">
        <div class="flex items-end space-x-4">
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-700 mb-1">Font Size</label>
            <input type="text"
                   data-type-scale-target="fontSizeInput"
                   placeholder="e.g., 48px, 2rem"
                   class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent">
          </div>
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-700 mb-1">Line Height</label>
            <input type="text"
                   data-type-scale-target="lineHeightInput"
                   placeholder="e.g., 1.5, 1.2"
                   class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent">
          </div>
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-700 mb-1">Variant</label>
            <select data-type-scale-target="variantInput"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent">
              <option value="Regular">Regular</option>
              <option value="Bold">Bold</option>
              <option value="Medium">Medium</option>
              <option value="Thin">Thin</option>
              <option value="Light">Light</option>
              <option value="SemiBold">SemiBold</option>
              <option value="ExtraBold">ExtraBold</option>
              <option value="Black">Black</option>
              <option value="Italic">Italic</option>
            </select>
          </div>
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-700 mb-1">Font Weight</label>
            <select data-type-scale-target="fontWeightInput"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-black focus:border-transparent">
              ${fontWeightOptions}
            </select>
          </div>
          <div>
            <button type="button"
                    data-type-scale-target="addButton"
                    data-action="click->type-scale#add"
                    class="bg-black hover:bg-gray-800 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
              Add Scale
            </button>
          </div>
        </div>
      </td>
    `

    return tr
  }

  getFontWeight(variant) {
    const weightMap = {
      "Thin": "100",
      "Light": "300",
      "Regular": "400",
      "Medium": "500",
      "SemiBold": "600",
      "Bold": "700",
      "ExtraBold": "800",
      "Black": "900",
      "Italic": "400"
    }
    return weightMap[variant] || "400"
  }

  updateHiddenFields() {
    // Remove existing hidden fields
    const existingFields = this.element.querySelectorAll('input[name^="typeface[type_scale]"]')
    existingFields.forEach(field => field.remove())

    // Add hidden fields for each scale as structured parameters
    this.scalesValue.forEach((scale, index) => {
      const fontSizeInput = document.createElement("input")
      fontSizeInput.type = "hidden"
      fontSizeInput.name = `typeface[type_scale][${index}][font_size]`
      fontSizeInput.value = scale.font_size || ""
      this.element.appendChild(fontSizeInput)

      const lineHeightInput = document.createElement("input")
      lineHeightInput.type = "hidden"
      lineHeightInput.name = `typeface[type_scale][${index}][line_height]`
      lineHeightInput.value = scale.line_height || ""
      this.element.appendChild(lineHeightInput)

      const variantInput = document.createElement("input")
      variantInput.type = "hidden"
      variantInput.name = `typeface[type_scale][${index}][variant]`
      variantInput.value = scale.variant || "Regular"
      this.element.appendChild(variantInput)

      const fontWeightInput = document.createElement("input")
      fontWeightInput.type = "hidden"
      fontWeightInput.name = `typeface[type_scale][${index}][font_weight]`
      fontWeightInput.value = scale.font_weight || "400"
      this.element.appendChild(fontWeightInput)
    })
  }

  saveScales() {
    // Create FormData with structured parameters
    const formData = new FormData()

    this.scalesValue.forEach((scale, index) => {
      formData.append(`typeface[type_scale][${index}][font_size]`, scale.font_size || "")
      formData.append(`typeface[type_scale][${index}][line_height]`, scale.line_height || "")
      formData.append(`typeface[type_scale][${index}][variant]`, scale.variant || "Regular")
      formData.append(`typeface[type_scale][${index}][font_weight]`, scale.font_weight || "400")
    })

    // Add typeface ID if it exists
    if (this.typefaceIdValue) {
      formData.append("typeface[id]", this.typefaceIdValue)
    }

    // Get CSRF token
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    // Submit via fetch
    fetch(`/brands/${this.brandIdValue}/typography/update_typeface`, {
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
      console.error('Error saving type scales:', error)
    })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

