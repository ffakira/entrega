import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slider"];

  get cards() {
    return Array.from(this.sliderTarget.children);
  }

  get maxScroll() {
    return Math.max(
      0,
      this.sliderTarget.scrollWidth - this.sliderTarget.clientWidth
    );
  }

  get isAtStart() {
    return this.sliderTarget.scrollLeft <= 2;
  }

  get isAtEnd() {
    return this.sliderTarget.scrollLeft >= this.maxScroll - 2;
  }

  get currentIndex() {
    const sliderLeft =
      this.sliderTarget.getBoundingClientRect().left +
      this.sliderTarget.clientLeft;

    return this.cards.reduce((closestIndex, card, index) => {
      const distance = Math.abs(
        card.getBoundingClientRect().left - sliderLeft
      );

      const closestDistance = Math.abs(
        this.cards[closestIndex].getBoundingClientRect().left - sliderLeft
      );

      return distance < closestDistance ? index : closestIndex;
    }, 0);
  }

  previous() {
    if (this.isAtStart) {
      this.scrollToPosition(this.maxScroll);
      return;
    }

    this.goToCard(this.currentIndex - 1);
  }

  next() {
    if (this.isAtEnd) {
      this.scrollToPosition(0);
      return;
    }

    this.goToCard(this.currentIndex + 1);
  }

  goToCard(index) {
    const card = this.cards[index];
    if (!card) return;

    const sliderRect = this.sliderTarget.getBoundingClientRect();
    const cardRect = card.getBoundingClientRect();

    const position =
      this.sliderTarget.scrollLeft +
      cardRect.left -
      sliderRect.left -
      this.sliderTarget.clientLeft;

    this.scrollToPosition(position);
  }

  scrollToPosition(position) {
    this.sliderTarget.scrollTo({
      left: Math.max(0, Math.min(position, this.maxScroll)),
      behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "auto"
        : "smooth"
    });
  }
}
