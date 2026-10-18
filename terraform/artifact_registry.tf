resource "google_artifact_registry_repository" "grocery_app" {
  project       = var.project_id
  location      = var.region
  repository_id = "grocery-app"
  description   = "container images for the grocery deal finders"
  format        = "DOCKER"

  depends_on = [google_project_service.required]
}