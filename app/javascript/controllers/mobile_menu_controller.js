import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "button", "openIcon", "closeIcon"];

  connect() {
    this.close();
  }

  disconnect() {
    document.body.classList.remove("menu-open");
  }

  toggle() {
    this.isOpen ? this.close() : this.open();
  }

  open() {
    this.menuTarget.classList.add("is-open");
    this.menuTarget.inert = false;

    this.buttonTarget.setAttribute("aria-expanded", "true");
    this.buttonTarget.setAttribute("aria-label", "Fechar menu");

    this.openIconTarget.hidden = true;
    this.closeIconTarget.hidden = false;

    document.body.classList.add("menu-open");
  }

  close() {
    if (!this.hasMenuTarget) return;

    this.menuTarget.classList.remove("is-open");
    this.menuTarget.inert = true;

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false");
      this.buttonTarget.setAttribute("aria-label", "Abrir menu");
    }

    if (this.hasOpenIconTarget) this.openIconTarget.hidden = false;
    if (this.hasCloseIconTarget) this.closeIconTarget.hidden = true;

    document.body.classList.remove("menu-open");
  }

  closeOnEscape(event) {
    if (event.key !== "Escape" || !this.isOpen) return;

    this.close();
    this.buttonTarget.focus();
  }

  closeOnResize() {
    if (window.innerWidth > 900 && this.isOpen) {
      this.close();
    }
  }

  get isOpen() {
    return this.hasMenuTarget && this.menuTarget.classList.contains("is-open");
  }
}
