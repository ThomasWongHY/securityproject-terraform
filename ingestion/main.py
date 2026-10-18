import logging
import os
import sys
import math
from datetime import date, datetime, timezone

from google.cloud import bigquery
import uuid
from zoneinfo import ZoneInfo

TORONTO_TZ = ZoneInfo("America/Toronto")
price_date = datetime.now(TORONTO_TZ).date().isoformat()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

PROJECT_ID = os.environ.get("GCP_PROJECT", "securityproject-terraform")
DATASET_ID = os.environ.get("BQ_DATASET", "grocery_data")

STAGING_TABLE_ID = f"{PROJECT_ID}.{DATASET_ID}.prices_batch_staging"
DESTINATION_TABLE_ID = f"{PROJECT_ID}.{DATASET_ID}.prices_batch_test"
RUN_TABLE_ID = f"{PROJECT_ID}.{DATASET_ID}.ingestion_run"

# SAMPLE DATA ONLY
SAMPLE_PRICES = [
    {
        "price_date": price_date,
        "product_id": "milk_2l",
        "store_id": "store_a",
        "price": 4.29,
        "unit_price": 2.145,
        "unit": "CAD/L",
        "source": "sample_data",
    },
    {
        "price_date": price_date,
        "product_id": "eggs_12",
        "store_id": "store_a",
        "price": 4.99,
        "unit_price": None,
        "unit": "CAD/12_pack",
        "source": "sample_data",
    },
    {
        "price_date": price_date,
        "product_id": "milk_2l",
        "store_id": "store_b",
        "price": 3.99,
        "unit_price": 1.995,
        "unit": "CAD/L",
        "source": "sample_data",
    },
]


def validate_price(record):
    required_fields = [
        "price_date",
        "product_id",
        "store_id",
        "price",
        "source",
    ]

    for field in required_fields:
        if record.get(field) is None or record.get(field) == "":
            return False, f"Missing required field: {field}"

    try:
        date.fromisoformat(record["price_date"])
    except (ValueError, TypeError):
        return False, "Invalid price_date"

    price = record["price"]

    if (
        isinstance(price, bool)
        or not isinstance(price, (int, float))
        or not math.isfinite(price)
        or price <= 0
    ):
        return False, "Price must be a finite number greater than zero"

    unit_price = record.get("unit_price")

    if unit_price is not None:
        if (
            isinstance(unit_price, bool)
            or not isinstance(unit_price, (int, float))
            or not math.isfinite(unit_price)
            or unit_price <= 0
        ):
            return False, "Unit price must be a finite number greater than zero"

    return True, "Valid"

def main():
    run_id = str(uuid.uuid4())
    started_at = datetime.now(timezone.utc)

    valid_records = []
    rejected_records = 0
    loaded_records = 0
    status = "FAILED"
    error_message = None

    logging.info("Ingestion started: run_id=%s", run_id)

    client = None

    try:
        for record in SAMPLE_PRICES:
            is_valid, reason = validate_price(record)

            if is_valid:
                valid_records.append(record)
            else:
                rejected_records += 1
                logging.warning(
                    "Rejected product_id=%s: %s",
                    record.get("product_id", "unknown"),
                    reason,
                )

        client = bigquery.Client(project=PROJECT_ID)

        # Testing
        # if os.environ.get("TEST_INGESTION_FAILURE") == "true":
        #     raise RuntimeError("Controlled failure test")

        if valid_records:
            rows = [
                {
                    **record,
                    "loaded_at": datetime.now(timezone.utc).isoformat(),
                }
                for record in valid_records
            ]

            # Replace the staging batch.
            staging_config = bigquery.LoadJobConfig(
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE
            )

            staging_job = client.load_table_from_json(
                rows,
                STAGING_TABLE_ID,
                job_config=staging_config,
            )
            staging_job.result()

            # Merge staged records into the destination.
            merge_sql = f"""
                MERGE `{DESTINATION_TABLE_ID}` AS target
                USING (
                    SELECT * EXCEPT(row_num)
                    FROM (
                        SELECT *,
                            ROW_NUMBER() OVER (
                                PARTITION BY
                                    price_date, product_id, store_id, source
                                ORDER BY loaded_at DESC
                            ) AS row_num
                        FROM `{STAGING_TABLE_ID}`
                    )
                    WHERE row_num = 1
                ) AS source
                ON target.price_date = source.price_date
                   AND target.product_id = source.product_id
                   AND target.store_id = source.store_id
                   AND target.source = source.source
                WHEN MATCHED THEN UPDATE SET
                    price = source.price,
                    unit_price = source.unit_price,
                    unit = source.unit,
                    loaded_at = source.loaded_at
                WHEN NOT MATCHED THEN INSERT (
                    price_date, product_id, store_id, price,
                    unit_price, unit, source, loaded_at
                )
                VALUES (
                    source.price_date, source.product_id, source.store_id,
                    source.price, source.unit_price, source.unit,
                    source.source, source.loaded_at
                )
            """

            merge_job = client.query(merge_sql)
            merge_job.result()

            loaded_records = len(valid_records)

            logging.info(
                "Data merge completed: run_id=%s staging_job=%s merge_job=%s",
                run_id,
                staging_job.job_id,
                merge_job.job_id,
            )

        status = "PARTIAL_FAILURE" if rejected_records else "SUCCESS"

    except Exception as exc:
        status = "FAILED"
        error_message = str(exc)[:1000]
        logging.exception("Ingestion failed: run_id=%s", run_id)

    completed_at = datetime.now(timezone.utc)

    # Write the final run record as a batch load.
    run_record = {
        "run_id": run_id,
        "started_at": started_at.isoformat(),
        "completed_at": completed_at.isoformat(),
        "status": status,
        "records_received": len(SAMPLE_PRICES),
        "records_loaded": loaded_records,
        "records_rejected": rejected_records,
        "error_message": error_message,
    }

    if client is not None:
        try:
            log_config = bigquery.LoadJobConfig(
                write_disposition=bigquery.WriteDisposition.WRITE_APPEND
            )

            log_job = client.load_table_from_json(
                [run_record],
                RUN_TABLE_ID,
                job_config=log_config,
            )
            log_job.result()

            logging.info(
                "Run log saved: run_id=%s status=%s",
                run_id,
                status,
            )

        except Exception:
            logging.exception("Could not save ingestion run log")
    
    else:
        logging.error(
            "Cannot save ingestion run log because BigQuery client "
            "was not initialized: run_id=%s",
            run_id,
        )

    logging.info(
        "Ingestion summary: run_id=%s status=%s received=%s "
        "validated=%s loaded=%s rejected=%s",
        run_id,
        status,
        len(SAMPLE_PRICES),
        len(valid_records),
        loaded_records,
        rejected_records,
    )

    if status != "SUCCESS":
        sys.exit(1)


if __name__ == "__main__":
    main()