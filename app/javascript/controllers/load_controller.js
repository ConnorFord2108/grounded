import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    console.log("hello2")
  }

  show() {
    console.log("hello3");
    this.buttonTarget.classList.add("d-none")
    document.querySelectorAll(".cards-to-load").forEach(card => {
      console.log(card.classList)
      card.classList.remove("d-none")
    })


  }
}
