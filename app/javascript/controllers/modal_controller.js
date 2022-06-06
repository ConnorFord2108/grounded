import { Controller } from "stimulus"
import "bootstrap"

export default class extends Controller {
  static targets = [ "container" ]

  close() {
    this.containerTarget.classList.add("d-none")
  }
}
