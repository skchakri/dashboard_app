import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audienceType", "messageTone", "platform", "submitButton"]
  
  connect() {
    this.updateSubmitButton()
  }

  audienceTypeChanged() {
    this.updateSubmitButton()
  }

  messageToneChanged() {
    this.updateSubmitButton()
  }

  updateSubmitButton() {
    const audienceSelected = this.hasAudienceTypeTarget && 
                            Array.from(this.audienceTypeTargets).some(radio => radio.checked)
    const toneSelected = this.hasMessageToneTarget && 
                        Array.from(this.messageToneTargets).some(radio => radio.checked)
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !(audienceSelected && toneSelected)
      
      if (audienceSelected && toneSelected) {
        this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        this.submitButtonTarget.classList.add('hover:bg-blue-700')
      } else {
        this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
        this.submitButtonTarget.classList.remove('hover:bg-blue-700')
      }
    }
  }

  // Add some visual feedback when options are selected
  selectOption(event) {
    const label = event.currentTarget
    const input = label.querySelector('input[type="radio"]')
    
    if (input) {
      // Remove selection from siblings
      const container = label.closest('.grid')
      if (container) {
        container.querySelectorAll('label').forEach(otherLabel => {
          otherLabel.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-50', 'dark:bg-blue-900')
        })
      }
      
      // Add selection to current
      label.classList.add('ring-2', 'ring-blue-500', 'bg-blue-50', 'dark:bg-blue-900')
      
      this.updateSubmitButton()
    }
  }
}