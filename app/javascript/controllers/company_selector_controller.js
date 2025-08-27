import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="company-selector"
export default class extends Controller {
  static targets = ["select", "form"]

  connect() {
    console.log("Company selector controller connected")
  }

  companyChanged() {
    const companyId = this.selectTarget.value
    if (companyId) {
      // Get the company subdomain from the option data attribute
      const selectedOption = this.selectTarget.options[this.selectTarget.selectedIndex]
      const subdomain = selectedOption.dataset.subdomain
      
      if (subdomain) {
        // Redirect to subdomain login page
        window.location.href = `http://${subdomain}.localhost:3000/login`
      }
    }
  }
}