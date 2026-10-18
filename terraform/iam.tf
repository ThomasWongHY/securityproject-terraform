resource "google_service_account" "rhel_vm" {
  project      = var.project_id
  account_id   = "rhel-lab-vm"
  display_name = "rhel VM"
  description  = "description identity for rhel security lab"
}

resource "google_project_iam_member" "rhel_os_admin" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "user:${var.admin_user_email}"
}

resource "google_project_iam_member" "rhel_iap_access" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "user:${var.admin_user_email}"
}

resource "google_service_account_iam_member" "rhel_vm_user" {
  service_account_id = google_service_account.rhel_vm.name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:${var.admin_user_email}"
}

resource "google_service_account" "grocery_ingestion" {
  project      = var.project_id
  account_id   = "grocery-ingestion-job"
  display_name = "Grocery Ingestion Job"
  description  = "Runtime identity for the grocery price ingestion pipeline"
}

resource "google_project_iam_member" "grocery_ingestion_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.grocery_ingestion.email}"
}

resource "google_bigquery_dataset_iam_member" "grocery_ingestion_data_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.grocery_ingestion.email}"
}
