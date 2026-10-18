resource "google_secret_manager_secret" "grocery_api_key" {
  project   = var.project_id
  secret_id = "grocery-api-key"

  replication {
    auto {}
  }

  labels = {
    environment = "lab"
    managed_by  = "terraform"
  }

  depends_on = [google_project_service.required]
}