import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="context-selector"
export default class extends Controller {
  static targets = ["select", "customField"]
  static values = { prompts: Array }

  connect() {
    this.updatePlaceholder()
    this.showSelectedDescription()
  }

  selectChanged() {
    this.updatePlaceholder()
    this.showSelectedDescription()
  }

  updatePlaceholder() {
    const selectedValue = this.selectTarget.value
    const textarea = this.customFieldTarget.querySelector('textarea')
    
    if (selectedValue === 'other') {
      textarea.placeholder = 'Enter your custom context...'
    } else if (selectedValue === '') {
      textarea.placeholder = 'Any specific message, promotion details, or context you\'d like to include...'
    } else {
      // Find the selected prompt and show its description in placeholder
      const selectedPrompt = this.promptsValue.find(p => p.id === selectedValue)
      if (selectedPrompt) {
        textarea.placeholder = `Selected: ${selectedPrompt.name}\n\nAdd any additional context here (optional)...`
      }
    }
  }

  showSelectedDescription() {
    const selectedValue = this.selectTarget.value
    
    // Hide all descriptions
    this.element.querySelectorAll('.context-description').forEach(desc => {
      desc.classList.add('hidden')
    })
    
    // Show selected description
    if (selectedValue && selectedValue !== 'other') {
      const selectedDesc = this.element.querySelector(`[data-context-id="${selectedValue}"]`)
      if (selectedDesc) {
        selectedDesc.classList.remove('hidden')
      }
    }
  }
}