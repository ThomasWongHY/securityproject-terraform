resource "google_service_account" "scheduler_invoker" {
  project      = var.project_id
  account_id   = "grocery-scheduler"
  display_name = "grocery scheduler invoker"
  description  = "identity used by scheduler to execute the grocery ingestion job"

  depends_on = [google_project_service.required]
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.grocery_ingestion.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.scheduler_invoker.email}"
}

resource "google_cloud_scheduler_job" "grocery_ingestion" {
  project     = var.project_id
  region      = var.region
  name        = "grocery-ingestion-daily"
  description = "Daily trigger for grocery price ingestion"

  schedule  = "0 2 * * *"
  time_zone = "America/Toronto"

  http_target {
    http_method = "POST"

    uri = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.grocery_ingestion.name}:run"

    body = base64encode("{}")

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = google_service_account.scheduler_invoker.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [
    google_project_service.required,
    google_cloud_run_v2_job_iam_member.scheduler_invoker
  ]
}