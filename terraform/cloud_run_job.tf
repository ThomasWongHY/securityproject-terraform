resource "google_cloud_run_v2_job" "grocery_ingestion" {
  project             = var.project_id
  name                = "grocery-ingestion"
  location            = var.region
  deletion_protection = true

  template {
    task_count  = 1
    parallelism = 1

    template {
      service_account = google_service_account.grocery_ingestion.email
      timeout         = "600s"
      max_retries     = 1

      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/grocery-app/grocery-ingestion:v3 "

        env {
          name  = "GCP_PROJECT"
          value = var.project_id
        }

        env {
          name  = "BQ_DATASET"
          value = google_bigquery_dataset.grocery_data.dataset_id
        }
      }
    }
  }

  depends_on = [
    google_project_service.required,
    google_project_iam_member.grocery_ingestion_job_user,
    google_bigquery_dataset_iam_member.grocery_ingestion_data_editor,
  ]
}