resource "google_bigquery_dataset" "grocery_data" {
  project     = var.project_id
  dataset_id  = "grocery_data"
  location    = var.region
  description = "grocery price"

  depends_on = [google_project_service.required]
}

resource "google_bigquery_table" "products" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  table_id   = "products"

  schema = jsonencode([
    { name = "product_id", type = "STRING", mode = "REQUIRED" },
    { name = "product_name", type = "STRING", mode = "REQUIRED" },
    { name = "brand", type = "STRING", mode = "NULLABLE" },
    { name = "category", type = "STRING", mode = "NULLABLE" },
  ])
}

resource "google_bigquery_table" "stores" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  table_id   = "stores"

  schema = jsonencode([
    { name = "store_id", type = "STRING", mode = "REQUIRED" },
    { name = "store_name", type = "STRING", mode = "REQUIRED" },
    { name = "postal code", type = "STRING", mode = "NULLABLE" },
    { name = "city", type = "STRING", mode = "NULLABLE" },
  ])
}

resource "google_bigquery_table" "prices" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  table_id   = "prices"

  schema = jsonencode([
    { name = "price_date", type = "DATE", mode = "REQUIRED" },
    { name = "product_id", type = "STRING", mode = "REQUIRED" },
    { name = "store_id", type = "STRING", mode = "REQUIRED" },
    { name = "price", type = "FLOAT64", mode = "REQUIRED" },
    { name = "unit_price", type = "FLOAT64", mode = "NULLABLE" },
    { name = "unit", type = "STRING", mode = "NULLABLE" },
    { name = "source", type = "STRING", mode = "NULLABLE" },
    { name = "loaded_at", type = "STRING", mode = "NULLABLE" },
  ])

  time_partitioning {
    type  = "DAY"
    field = "price_date"
  }
}

resource "google_bigquery_table" "ingestion_run" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  table_id   = "ingestion_run"

  schema = jsonencode([
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "started_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "completed_at", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "records_received", type = "INT64", mode = "NULLABLE" },
    { name = "records_loaded", type = "INT64", mode = "NULLABLE" },
    { name = "records_rejected", type = "INT64", mode = "NULLABLE" },
    { name = "error_message", type = "STRING", mode = "NULLABLE" },
  ])
}


resource "google_bigquery_table" "prices_batch_test" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  table_id   = "prices_batch_test"

  description = "Temporary test table for batch grocery price ingestion"

  schema = jsonencode([
    {
      name = "price_date"
      type = "DATE"
      mode = "REQUIRED"
    },
    {
      name = "product_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "store_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "price"
      type = "FLOAT"
      mode = "REQUIRED"
    },
    {
      name = "unit_price"
      type = "FLOAT"
      mode = "NULLABLE"
    },
    {
      name = "unit"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "source"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "loaded_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    }
  ])

  time_partitioning {
    type  = "DAY"
    field = "price_date"
  }

  depends_on = [google_project_service.required]
}


resource "google_bigquery_table" "prices_batch_staging" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.grocery_data.dataset_id
  table_id   = "prices_batch_staging"

  description = "Staging table for repeat-safe grocery price ingestion"


  schema = jsonencode([
    {
      name = "source"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "unit"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "unit_price"
      type = "FLOAT"
      mode = "NULLABLE"
    },
    {
      name = "price"
      type = "FLOAT"
      mode = "NULLABLE"
    },
    {
      name = "store_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "loaded_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "product_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "price_date"
      type = "DATE"
      mode = "NULLABLE"
    }
  ])

  depends_on = [google_project_service.required]
}