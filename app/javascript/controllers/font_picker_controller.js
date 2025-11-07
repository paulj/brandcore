import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "searchInput",
    "results",
    "suggestions",
    "selectedFont",
    "form",
    "preview"
  ]

  static values = {
    brandId: String,
    currentFont: Object
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

  openModal() {
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
    if (!this.currentFontValue) return

    const fontData = this.currentFontValue
    const fontName = fontData.family

    // Update the hidden form field
    const input = this.formTarget.querySelector('input[name="brand_typography[primary_typeface]"]')
    if (input) {
      const fontPayload = {
        name: fontName,
        family: fontName,
        category: fontData.category,
        variants: fontData.variants || [],
        subsets: fontData.subsets || [],
        google_fonts_url: `https://fonts.googleapis.com/css2?family=${fontName.replace(/\s+/g, "+")}:wght@300;400;500;600;700&display=swap`
      }
      input.value = JSON.stringify(fontPayload)
      
      // Load the Google Font CSS
      this.loadGoogleFont(fontName)
    }

    // Submit the form via Turbo
    const formData = new FormData(this.formTarget)
    fetch(this.formTarget.action, {
      method: this.formTarget.method,
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
      this.closeModal()
      // Reload page to show updated font
      window.location.reload()
    })
    .catch(error => {
      console.error('Error saving font:', error)
    })
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

