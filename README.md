Grocery Deal Finder

A GCP and Terraform project

The goal is to build a simple grocery price tool for compare prices, find the best store to buy grocery, track the grocery index.

What it does

1. Uses Terraform to manage GCP infrastructure.
2. Runs a private RHEL 9 VM for Linux and security practice.
3. Uses VPC firewall rules and IAP to control SSH access.
4. Builds and stores a Python ingestion container in Artifact Registry.
5. Runs scheduled ingestion jobs with Cloud Run Jobs and Cloud Scheduler.
6. Stores sample grocery price data and execution records in BigQuery.
7. Uses dedicated service accounts and IAM permissions to limit access.

How it works

1. Cloud Scheduler triggers a Cloud Run Job.
2. A Python script validates sample grocery prices.
3. The data is inserted to BigQuery tables.
4. An audit record is saved to track the run.

Currently, the pipeline uses sample data. The next step is to connect to a stable API for grocery prices (Price, Unit, Date, Store, Postal Code, etc).

Project structure

* terraform/ — GCP infrastructure and IAM configuration.
* ingestion/ — Python application, Dockerfile, and dependencies.
* README.md — Project notes and setup instructions.

How to start

Terraform, the Google Cloud CLI, Docker, and a GCP project with billing enabled.

1. Clone the repository and authenticate with GCP.
2. Create terraform/terraform.tfvars using the example configuration.
3. Run the following commands from the terraform/ directory:
terraform init
terraform validate
terraform plan

4. Review the plan before applying any changes.

**Make sure the container image referenced in the Terraform configuration has been built and pushed to Artifact Registry before deploying the Cloud Run Job.**

What I’m learning

* Infrastructure as code with Terraform
* GCP networking and IAM
* Linux administration and secure remote access with RHEL
* Container builds and Cloud Run Jobs
* BigQuery data processing
* Scheduled automation and troubleshooting

**Sample data is used for now.**