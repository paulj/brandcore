import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "searchInput",
    "results",
    "suggestions",
    "selectedFont",
    "form",
    "preview",
    "primaryName",
    "primaryFamily",
    "primaryCategory",
    "primaryGoogleFontsUrl",
    "primaryTypefaceFields",
    "secondaryName",
    "secondaryFamily",
    "secondaryCategory",
    "secondaryGoogleFontsUrl",
    "secondaryTypefaceFields",
    "typefaceRole"
  ]

  static values = {
    brandId: String,
    currentFont: Object,
    typefaceRole: String
  }

  connect() {
    this.timeout = null
    this.loading = false
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  openModal(event) {
    // Get the typeface role from the button that was clicked
    const role = event?.currentTarget?.dataset?.typefaceRole || "primary"
    this.typefaceRoleValue = role
    
    // Update the modal header to show which typeface is being selected
    if (this.hasTypefaceRoleTarget) {
      this.typefaceRoleTarget.textContent = role.charAt(0).toUpperCase() + role.slice(1)
    }
    
    this.modalTarget.classList.remove("hidden")
    this.loadSuggestions()
    this.searchInputTarget.focus()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    this.searchInputTarget.value = ""
  }

  search() {
    const query = this.searchInputTarget.value.trim()

    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce search by 300ms
    this.timeout = setTimeout(() => {
      if (query.length === 0) {
        this.loadSuggestions()
        return
      }

      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    if (this.loading) return

    this.loading = true
    this.showLoading()

    try {
      const response = await fetch(
        `/brands/${this.brandIdValue}/typography/search_fonts?q=${encodeURIComponent(query)}`,
        {
          headers: {
            "Accept": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
          }
        }
      )

      const data = await response.json()
      this.displayFonts(data.fonts)
    } catch (error) {
      console.error("Error searching fonts:", error)
      this.showError("Failed to search fonts. Please try again.")
    } finally {
      this.loading = false
    }
  }

  async loadSuggestions() {
    if (this.loading) return

    this.loading = true
    this.showLoading()

    try {
      const response = await fetch(
        `/brands/${this.brandIdValue}/typography/suggest_fonts`,
        {
          headers: {
            "Accept": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
          }
        }
      )

      const data = await response.json()
      this.displayFonts(data.fonts, true)
    } catch (error) {
      console.error("Error loading suggestions:", error)
      this.showError("Failed to load font suggestions. Please try again.")
    } finally {
      this.loading = false
    }
  }

  async loadByCategory(event) {
    const category = event.currentTarget.dataset.category
    if (!category || this.loading) return

    this.loading = true
    this.showLoading()

    try {
      const response = await fetch(
        `/brands/${this.brandIdValue}/typography/fonts_by_category?category=${encodeURIComponent(category)}`,
        {
          headers: {
            "Accept": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
          }
        }
      )

      const data = await response.json()
      this.displayFonts(data.fonts)
    } catch (error) {
      console.error("Error loading fonts by category:", error)
      this.showError("Failed to load fonts. Please try again.")
    } finally {
      this.loading = false
    }
  }

  selectFont(event) {
    event.stopPropagation()
    const fontData = JSON.parse(event.currentTarget.dataset.font)
    this.currentFontValue = fontData
    
    // Load font for preview
    this.loadGoogleFont(fontData.family)
    
    // Update preview after a short delay to allow font to load
    setTimeout(() => {
      this.updatePreview(fontData)
      this.updateSelectedDisplay(fontData)
    }, 100)
  }

  confirmSelection() {
    if (!this.currentFontValue) {
      console.warn("No font selected")
      return
    }

    const fontData = this.currentFontValue
    const fontName = fontData.family
    const role = this.typefaceRoleValue || "primary"

    // Determine which targets to use based on the role
    const nameTarget = role === "secondary" ? "secondaryName" : "primaryName"
    const familyTarget = role === "secondary" ? "secondaryFamily" : "primaryFamily"
    const categoryTarget = role === "secondary" ? "secondaryCategory" : "primaryCategory"
    const googleFontsUrlTarget = role === "secondary" ? "secondaryGoogleFontsUrl" : "primaryGoogleFontsUrl"
    const fieldsContainerTarget = role === "secondary" ? "secondaryTypefaceFields" : "primaryTypefaceFields"

    // Get the field container
    const fieldsContainer = this[`${fieldsContainerTarget}Target`]
    if (!fieldsContainer) {
      console.error(`Could not find ${role} typeface fields container`)
      alert("Error: Could not find form fields. Please refresh the page and try again.")
      return
    }

    // Update the basic fields
    this[`${nameTarget}Target`].value = fontName
    this[`${familyTarget}Target`].value = fontName
    this[`${categoryTarget}Target`].value = fontData.category || ""
    this[`${googleFontsUrlTarget}Target`].value = `https://fonts.googleapis.com/css2?family=${fontName.replace(/\s+/g, "+")}:wght@300;400;500;600;700&display=swap`

    // Remove existing variant and subset fields
    const existingVariants = fieldsContainer.querySelectorAll('input[name*="[variants][]"]')
    const existingSubsets = fieldsContainer.querySelectorAll('input[name*="[subsets][]"]')
    existingVariants.forEach(field => field.remove())
    existingSubsets.forEach(field => field.remove())

    // Add variant fields
    const variants = fontData.variants || []
    variants.forEach(variant => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = `brand_typography[${role}_typeface][variants][]`
      input.value = variant
      fieldsContainer.appendChild(input)
    })

    // Add subset fields
    const subsets = fontData.subsets || []
    subsets.forEach(subset => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = `brand_typography[${role}_typeface][subsets][]`
      input.value = subset
      fieldsContainer.appendChild(input)
    })
    
    // Load the Google Font CSS
    this.loadGoogleFont(fontName)

    // Submit the form - Turbo will handle the page update
    this.formTarget.requestSubmit()
  }

  loadGoogleFont(fontFamily) {
    // Check if font is already loaded
    const linkId = `google-font-${fontFamily.replace(/\s+/g, '-').toLowerCase()}`
    if (document.getElementById(linkId)) return

    const link = document.createElement('link')
    link.id = linkId
    link.rel = 'stylesheet'
    link.href = `https://fonts.googleapis.com/css2?family=${fontFamily.replace(/\s+/g, '+')}:wght@300;400;500;600;700&display=swap`
    document.head.appendChild(link)
  }

  displayFonts(fonts, isSuggestions = false) {
    const container = isSuggestions ? this.suggestionsTarget : this.resultsTarget
    container.innerHTML = ""

    if (!fonts || fonts.length === 0) {
      const message = isSuggestions 
        ? '<p class="text-gray-500 text-center py-8 col-span-2">No suggestions available. Try searching for fonts above.</p>'
        : '<p class="text-gray-500 text-center py-8 col-span-2">No fonts found. Try a different search term.</p>'
      container.innerHTML = message
      return
    }

    fonts.forEach(font => {
      const fontElement = this.createFontCard(font)
      container.appendChild(fontElement)
    })
  }

  createFontCard(font) {
    const card = document.createElement("div")
    card.className = "border border-gray-200 rounded-lg p-4 hover:border-black cursor-pointer transition-colors"
    card.dataset.font = JSON.stringify(font)
    card.dataset.action = "click->font-picker#selectFont"

    const fontFamily = font.family || "Unknown"
    const category = font.category || "unknown"

    card.innerHTML = `
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <h4 class="font-semibold text-gray-900 mb-1" style="font-family: '${fontFamily}', sans-serif">${fontFamily}</h4>
          <p class="text-xs text-gray-500 capitalize">${category}</p>
          ${font.variants ? `<p class="text-xs text-gray-400 mt-1">${font.variants.length} variants</p>` : ""}
        </div>
      </div>
      <div class="mt-3 text-sm" style="font-family: '${fontFamily}', sans-serif">
        <p class="text-gray-700">The quick brown fox jumps over the lazy dog</p>
        <p class="text-gray-500 mt-1">ABCDEFGHIJKLMNOPQRSTUVWXYZ</p>
        <p class="text-gray-500">0123456789</p>
      </div>
    `

    return card
  }

  updatePreview(font) {
    if (!this.hasPreviewTarget) return

    const fontFamily = font.family || "Unknown"
    this.previewTarget.style.fontFamily = `'${fontFamily}', sans-serif`
  }

  updateSelectedDisplay(font) {
    if (!this.hasSelectedFontTarget) return

    const fontFamily = font.family || "Unknown"
    this.selectedFontTarget.innerHTML = `
      <div class="flex items-center justify-between">
        <div>
          <h4 class="font-semibold text-gray-900" style="font-family: '${fontFamily}', sans-serif">${fontFamily}</h4>
          <p class="text-xs text-gray-500 capitalize">${font.category || "unknown"}</p>
        </div>
        <button
          type="button"
          class="bg-black text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-800 transition-colors"
          data-action="click->font-picker#confirmSelection"
        >
          Select Font
        </button>
      </div>
    `
  }

  showLoading() {
    const container = this.resultsTarget
    container.innerHTML = '<p class="text-gray-500 text-center py-8 col-span-2">Loading fonts...</p>'
  }

  showError(message) {
    const container = this.resultsTarget
    container.innerHTML = `<p class="text-red-500 text-center py-8 col-span-2">${message}</p>`
  }
}


