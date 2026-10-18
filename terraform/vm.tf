data "google_compute_image" "rhel9" {
  project = "rhel-cloud"
  family  = "rhel-9"
}

resource "google_compute_instance" "rhel_lab" {
  project      = var.project_id
  name         = "grocery-rhel-lab"
  zone         = var.zone
  machine_type = "e2-small"

  tags = ["rhel-lab"]

  labels = {
    environment = "lab"
    managed_by  = "terraform"
    purpose     = "cybersecurity-training"
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image = data.google_compute_image.rhel9.self_link
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.lab.id
    subnetwork = google_compute_subnetwork.lab.id
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  service_account {
    email  = google_service_account.rhel_vm.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true

  depends_on = [
    google_project_iam_member.rhel_os_admin,
    google_project_iam_member.rhel_iap_access,
    google_service_account_iam_member.rhel_vm_user
  ]
}