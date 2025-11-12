import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["generateBtn", "palettesContainer", "loadingState", "emptyState"]
  static values = {
    generateUrl: String,
    applyUrl: String
  }

  connect() {
    this.isGenerating = false
  }

  async generate() {
    if (this.isGenerating) return

    this.isGenerating = true
    this.showLoading()

    try {
      const response = await fetch(this.generateUrlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.getCSRFToken()
        }
      })

      if (!response.ok) {
        const error = await response.json()
        this.showError(error.error || "Failed to generate palettes")
        return
      }

      const data = await response.json()
      this.displayPalettes(data.palettes)
    } catch (error) {
      console.error("Palette generation error:", error)
      this.showError("An unexpected error occurred. Please try again.")
    } finally {
      this.isGenerating = false
      this.hideLoading()
    }
  }

  async applyPalette(event) {
    const paletteCard = event.currentTarget.closest("[data-palette-index]")
    const paletteIndex = parseInt(paletteCard.dataset.paletteIndex)
    const paletteData = this.currentPalettes[paletteIndex]

    if (!paletteData) {
      console.error("Palette data not found")
      return
    }

    try {
      const response = await fetch(this.applyUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.getCSRFToken()
        },
        body: JSON.stringify({ palette: paletteData })
      })

      if (!response.ok) {
        throw new Error("Failed to apply palette")
      }

      // Turbo Stream will handle the update
    } catch (error) {
      console.error("Palette application error:", error)
      alert("Failed to apply palette. Please try again.")
    }
  }

  showLoading() {
    if (this.hasGenerateBtnTarget) {
      this.generateBtnTarget.disabled = true
      this.generateBtnTarget.innerHTML = '<i class="fa-solid fa-spinner fa-spin mr-2"></i>Generating...'
    }
    if (this.hasLoadingStateTarget) {
      this.loadingStateTarget.classList.remove("hidden")
    }
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add("hidden")
    }
  }

  hideLoading() {
    if (this.hasGenerateBtnTarget) {
      this.generateBtnTarget.disabled = false
      this.generateBtnTarget.innerHTML = '<i class="fa-solid fa-magic-wand-sparkles mr-2"></i>AI Generate'
    }
    if (this.hasLoadingStateTarget) {
      this.loadingStateTarget.classList.add("hidden")
    }
  }

  displayPalettes(palettes) {
    if (!this.hasPalettesContainerTarget) return

    this.currentPalettes = palettes
    this.palettesContainerTarget.innerHTML = ""

    palettes.forEach((palette, index) => {
      const card = this.createPaletteCard(palette, index)
      this.palettesContainerTarget.appendChild(card)
    })
  }

  createPaletteCard(palette, index) {
    const card = document.createElement("div")
    card.className = "bg-white border border-gray-200 rounded-xl p-6 cursor-pointer hover:shadow-lg transition-all hover:border-gray-400"
    card.dataset.paletteIndex = index
    card.dataset.action = "click->palette-generator#applyPalette"

    const primaryColor = palette.colors.find(c => c.role === "primary")
    const primaryHex = primaryColor?.hex || "#666666"

    // Determine text color based on background brightness
    const textColor = this.getContrastColor(primaryHex)

    card.innerHTML = `
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="text-lg font-medium text-gray-900">${this.formatSchemeName(palette.scheme)}</h3>
          <p class="text-sm text-gray-500">${palette.metadata?.description || palette.metadata?.vibe || ""}</p>
        </div>
        <div class="w-6 h-6 rounded-full border-2 border-white shadow-lg" style="background-color: ${primaryHex}"></div>
      </div>
      <div class="flex space-x-1 mb-4">
        ${palette.colors.slice(0, 5).map(color => `
          <div class="flex-1 h-12 rounded" style="background-color: ${color.hex}"></div>
        `).join("")}
      </div>
      <div class="flex items-center justify-between text-xs text-gray-500">
        <span>${palette.colors.length} colours</span>
        ${palette.accessible ? '<span class="text-green-600"><i class="fa-solid fa-check-circle mr-1"></i>Accessible</span>' : '<span class="text-amber-600"><i class="fa-solid fa-exclamation-circle mr-1"></i>Review needed</span>'}
      </div>
    `

    return card
  }

  formatSchemeName(scheme) {
    return scheme
      .split("-")
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ")
  }

  getContrastColor(hex) {
    // Convert hex to RGB
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)

    // Calculate relative luminance
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

    // Return white text for dark backgrounds, black for light
    return luminance > 0.5 ? "#1F2937" : "#FFFFFF"
  }

  showError(message) {
    alert(message)
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ""
  }
}
