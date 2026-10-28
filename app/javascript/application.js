// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import Alpine from "alpinejs"
import recordShelf from "./record_shelf"

window.Alpine = Alpine
Alpine.data("recordShelf", recordShelf)
Alpine.start()
