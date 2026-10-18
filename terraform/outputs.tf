output "rhel_vm_name" {
  description = "name of rhel vm"
  value       = google_compute_instance.rhel_lab.name
}

output "rhel_vm_zone" {
  description = "zone hosting vm"
  value       = google_compute_instance.rhel_lab.zone
}

output "rhel_vm_private_ip" {
  description = "private IP address of vm"
  value       = google_compute_instance.rhel_lab.network_interface[0].network_ip
}