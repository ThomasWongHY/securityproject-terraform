resource "google_compute_network" "lab" {
  name                    = "grocery-lab-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "lab" {
  name                     = "grocery-lab-subnet"
  region                   = var.region
  network                  = google_compute_network.lab.id
  ip_cidr_range            = "10.20.0.0/24"
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "grocery-lab-allow-iap-ssh"
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["rhel-lab"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  description = "Allow SSH through Identity-Aware Proxy only"
}