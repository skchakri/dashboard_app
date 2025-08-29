import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    platform: String, 
    maxChars: Number 
  }
  
  static targets = ["editor", "charCount", "charStatus"]

  connect() {
    this.updateCharacterCount()
    
    // Initialize editor with better defaults
    if (this.hasEditorTarget) {
      this.editorTarget.style.minHeight = '120px'
      this.editorTarget.addEventListener('input', () => this.updateCharacterCount())
      this.editorTarget.addEventListener('paste', (e) => this.handlePaste(e))
      this.editorTarget.addEventListener('keydown', (e) => this.handleKeydown(e))
    }
  }

  updateCharacterCount() {
    if (!this.hasEditorTarget) return
    
    const currentChars = this.editorTarget.innerText?.length || 0
    const maxChars = this.maxCharsValue
    
    // Update character count display
    if (this.hasCharCountTarget) {
      const currentSpan = this.charCountTarget.querySelector(`#current-chars-${this.platformValue}`)
      if (currentSpan) {
        currentSpan.textContent = currentChars
      }
    }
    
    // Update status and styling
    if (this.hasCharStatusTarget) {
      if (currentChars > maxChars) {
        this.charStatusTarget.textContent = 'Over limit!'
        this.charStatusTarget.className = 'text-red-600 font-medium'
        this.editorTarget.classList.add('border-red-500', 'ring-1', 'ring-red-200')
        this.editorTarget.classList.remove('border-gray-300', 'border-yellow-500', 'ring-yellow-200')
      } else if (currentChars > maxChars * 0.9) {
        this.charStatusTarget.textContent = 'Getting close'
        this.charStatusTarget.className = 'text-yellow-600 font-medium'
        this.editorTarget.classList.add('border-yellow-500', 'ring-1', 'ring-yellow-200')
        this.editorTarget.classList.remove('border-gray-300', 'border-red-500', 'ring-red-200')
      } else {
        this.charStatusTarget.textContent = 'Good'
        this.charStatusTarget.className = 'text-green-600'
        this.editorTarget.classList.remove('border-red-500', 'ring-red-200', 'border-yellow-500', 'ring-yellow-200')
        this.editorTarget.classList.add('border-gray-300')
      }
    }
    
    // Dispatch custom event for other components
    this.dispatch('characterCountUpdated', { 
      detail: { 
        platform: this.platformValue, 
        currentChars, 
        maxChars,
        isOverLimit: currentChars > maxChars
      } 
    })
  }

  handlePaste(event) {
    event.preventDefault()
    
    // Get pasted text as plain text only
    const pastedText = (event.clipboardData || window.clipboardData).getData('text/plain')
    
    // Insert as plain text
    this.insertTextAtCursor(pastedText)
    this.updateCharacterCount()
  }

  handleKeydown(event) {
    // Handle keyboard shortcuts
    if (event.metaKey || event.ctrlKey) {
      switch (event.key) {
        case 'b':
          event.preventDefault()
          this.formatText('bold')
          break
        case 'i':
          event.preventDefault()
          this.formatText('italic')
          break
        case 'z':
          if (event.shiftKey) {
            event.preventDefault()
            document.execCommand('redo', false, null)
          } else {
            event.preventDefault()
            document.execCommand('undo', false, null)
          }
          break
      }
    }
    
    // Prevent newlines on certain platforms
    if (event.key === 'Enter') {
      if (this.platformValue === 'twitter') {
        // Allow newlines but warn if getting close to limit
        const currentChars = this.editorTarget.innerText?.length || 0
        if (currentChars > this.maxCharsValue * 0.8) {
          this.showNotification('Consider keeping Twitter posts concise', 'warning')
        }
      }
    }
  }

  formatText(command) {
    this.editorTarget.focus()
    
    const selection = window.getSelection()
    if (selection.rangeCount > 0 && !selection.isCollapsed) {
      document.execCommand(command, false, null)
      this.updateCharacterCount()
    } else {
      this.showNotification('Please select text to format', 'warning')
    }
  }

  insertEmoji(emoji) {
    this.insertTextAtCursor(emoji)
    this.updateCharacterCount()
  }

  insertTextAtCursor(text) {
    const selection = window.getSelection()
    
    if (selection.rangeCount > 0) {
      const range = selection.getRangeAt(0)
      range.deleteContents()
      
      const textNode = document.createTextNode(text)
      range.insertNode(textNode)
      
      // Move cursor after inserted text
      range.setStartAfter(textNode)
      range.setEndAfter(textNode)
      selection.removeAllRanges()
      selection.addRange(range)
    } else {
      // Fallback: append to end
      this.editorTarget.focus()
      const textNode = document.createTextNode(text)
      this.editorTarget.appendChild(textNode)
      
      const range = document.createRange()
      range.setStartAfter(textNode)
      selection.removeAllRanges()
      selection.addRange(range)
    }
  }

  copyContent() {
    const editedText = this.editorTarget.innerText || this.editorTarget.textContent || ''
    
    navigator.clipboard.writeText(editedText).then(() => {
      this.showNotification('Content copied to clipboard!', 'success')
    }).catch((err) => {
      console.error('Could not copy text: ', err)
      this.showNotification('Failed to copy content', 'error')
    })
  }

  resetContent() {
    const originalContent = this.editorTarget.dataset.originalContent
    if (originalContent) {
      this.editorTarget.innerHTML = originalContent
      this.updateCharacterCount()
      this.showNotification('Content reset to original', 'info')
    }
  }

  checkCharacterCount() {
    const currentChars = this.editorTarget.innerText?.length || 0
    const remaining = this.maxCharsValue - currentChars
    
    if (remaining >= 0) {
      this.showNotification(`${currentChars} characters used, ${remaining} remaining`, 'info')
    } else {
      this.showNotification(`${Math.abs(remaining)} characters over limit!`, 'error')
    }
  }

  showNotification(message, type = 'info') {
    // Dispatch event that can be caught by notification system
    this.dispatch('notification', { 
      detail: { message, type } 
    })
    
    // Fallback to global notification function if available
    if (typeof window.showNotification === 'function') {
      window.showNotification(message, type)
    }
  }
}