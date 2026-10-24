import { Controller } from "@hotwired/stimulus"

// Opens and closes the sidebar as a drawer on narrow screens.
export default class extends Controller {
  static targets = [ "toggle" ]

  connect() {
    this.closeOnEscape = (event) => { if (event.key === "Escape") this.close() }
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  toggle() {
    this.element.classList.contains("is-open") ? this.close() : this.open()
  }

  open() {
    this.element.classList.add("is-open")
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.element.classList.remove("is-open")
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }
}
