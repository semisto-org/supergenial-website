import { Controller } from "@hotwired/stimulus"

// ⌘K palette (search pages, actions and records) and "G then <key>" shortcuts.
export default class extends Controller {
  static targets = [ "dialog", "input", "list" ]
  static values = { url: String }

  connect() {
    this.results = []
    this.selected = 0
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    clearTimeout(this.searchTimer)
  }

  onKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault()
      this.dialogTarget.open ? this.dialogTarget.close() : this.open()
      return
    }
    if (this.dialogTarget.open || event.metaKey || event.ctrlKey || event.altKey || this.isTyping(event.target)) return

    if (this.awaitingShortcut) {
      this.awaitingShortcut = false
      const link = document.querySelector(`[data-shortcut="${event.key.toLowerCase()}"]`)
      if (link) {
        event.preventDefault()
        Turbo.visit(link.href)
      }
    } else if (event.key === "g") {
      this.awaitingShortcut = true
      setTimeout(() => { this.awaitingShortcut = false }, 1000)
    } else if (event.key === "/") {
      event.preventDefault()
      this.open()
    }
  }

  open() {
    this.dialogTarget.showModal()
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.fetchResults()
  }

  reset() {
    this.inputTarget.value = ""
    this.listTarget.replaceChildren()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }

  search() {
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => this.fetchResults(), 120)
  }

  navigate(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      this.select((this.selected + step + this.results.length) % Math.max(this.results.length, 1))
    } else if (event.key === "Enter") {
      event.preventDefault()
      this.go(this.selected)
    }
  }

  async fetchResults() {
    const query = this.inputTarget.value.trim()
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok || query !== this.inputTarget.value.trim()) return
    this.results = (await response.json()).results
    this.render(query)
  }

  render(query) {
    const items = []
    let group = null
    this.results.forEach((result, index) => {
      if (result.group !== group) {
        group = result.group
        const heading = document.createElement("li")
        heading.className = "palette__group"
        heading.setAttribute("role", "presentation")
        heading.textContent = group
        items.push(heading)
      }
      const item = document.createElement("li")
      item.className = "palette__item"
      item.id = `palette-item-${index}`
      item.setAttribute("role", "option")
      const label = document.createElement("span")
      label.textContent = result.label
      item.append(label)
      if (result.hint) {
        const hint = document.createElement("small")
        hint.textContent = result.hint
        item.append(hint)
      }
      item.addEventListener("click", () => this.go(index))
      item.addEventListener("mousemove", () => this.select(index))
      items.push(item)
    })
    if (this.results.length === 0) {
      const empty = document.createElement("li")
      empty.className = "palette__empty"
      empty.textContent = `Aucun résultat pour « ${query} ».`
      items.push(empty)
    }
    this.listTarget.replaceChildren(...items)
    this.select(0)
  }

  select(index) {
    this.selected = index
    this.listTarget.querySelectorAll(".palette__item").forEach((item, i) => item.setAttribute("aria-selected", i === index))
    const current = this.listTarget.querySelector(`#palette-item-${index}`)
    if (current) {
      current.scrollIntoView({ block: "nearest" })
      this.inputTarget.setAttribute("aria-activedescendant", current.id)
    }
  }

  go(index) {
    const result = this.results[index]
    if (!result) return
    this.dialogTarget.close()
    Turbo.visit(result.url)
  }

  isTyping(element) {
    return element.isContentEditable || [ "INPUT", "TEXTAREA", "SELECT" ].includes(element.tagName)
  }
}
