variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "northamerica-northeast2"
}

variable "zone" {
  description = "Compute Engine zone for the lab VM"
  type        = string
  default     = "northamerica-northeast2-a"
}

variable "admin_user_email" {
  description = "Google account email for the lab administrator"
  type        = string
}