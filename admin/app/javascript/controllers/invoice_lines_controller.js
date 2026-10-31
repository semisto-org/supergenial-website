import { Controller } from "@hotwired/stimulus"

// Adds and removes invoice lines in the form, without saving first.
export default class extends Controller {
  static targets = [ "body", "template", "line", "destroy" ]

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_LINE/g, `${Date.now()}`)
    this.bodyTarget.insertAdjacentHTML("beforeend", html)
    const row = this.lineTargets[this.lineTargets.length - 1]
    row.querySelector("input[name$='[position]']").value = this.lineTargets.length - 1
    row.querySelector("input[name$='[description]']").focus()
  }

  // A saved line is flagged for destruction and hidden; a new one simply leaves the form.
  remove(event) {
    const row = event.target.closest("tr")
    if (row.querySelector("input[name$='[id]']")) {
      row.querySelector("input[name$='[_destroy]']").value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
  }
}
