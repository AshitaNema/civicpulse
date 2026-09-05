import os
import random
from datetime import datetime, timedelta
from google.cloud import bigquery
from google.api_core.exceptions import NotFound

PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "civicpulse-507101")
DATASET_ID = "civicpulse_data"
TABLE_ID = f"{PROJECT_ID}.{DATASET_ID}.reports"

WARDS = [f"Ward_{i}" for i in range(1, 11)]

# Weighted selections
ISSUE_TYPES = ["pothole", "garbage", "streetlight", "leakage", "road_damage"]
ISSUE_WEIGHTS = [0.40, 0.20, 0.15, 0.15, 0.10]

SEVERITIES = ["low", "medium", "critical"]
SEVERITY_WEIGHTS = [0.50, 0.35, 0.15]

STATUSES = ["open", "in_progress", "resolved", "false_closure"]
STATUS_WEIGHTS = [0.20, 0.30, 0.40, 0.10]

def get_season(month: int) -> str:
    if 6 <= month <= 9:
        return "monsoon"
    elif 3 <= month <= 5:
        return "summer"
    else:
        return "winter"

def generate_rows(n: int = 500) -> list:
    now = datetime.utcnow()
    rows = []

    for i in range(1, n + 1):
        report_id = f"CP-{i:04d}"
        ward = random.choice(WARDS)
        issue_type = random.choices(ISSUE_TYPES, weights=ISSUE_WEIGHTS, k=1)[0]
        severity = random.choices(SEVERITIES, weights=SEVERITY_WEIGHTS, k=1)[0]
        status = random.choices(STATUSES, weights=STATUS_WEIGHTS, k=1)[0]

        # Random date within last 365 days
        random_days = random.randint(0, 365)
        random_seconds = random.randint(0, 86400)
        created_dt = now - timedelta(days=random_days, seconds=random_seconds)
        created_at = created_dt.isoformat()

        season = get_season(created_dt.month)

        if status in ["resolved", "false_closure"]:
            resolution_time_days = random.randint(1, 30)
            verified_resolution = random.choices([True, False], weights=[0.80, 0.20], k=1)[0]
        else:
            resolution_time_days = None
            verified_resolution = None

        rows.append({
            "report_id": report_id,
            "ward": ward,
            "issue_type": issue_type,
            "severity": severity,
            "created_at": created_at,
            "status": status,
            "resolution_time_days": resolution_time_days,
            "verified_resolution": verified_resolution,
            "season": season,
        })

    return rows

def main():
    print(f"Connecting to BigQuery project: {PROJECT_ID}...")
    client = bigquery.Client(project=PROJECT_ID, location="us-central1")

    # 1. Ensure dataset exists
    dataset_ref = bigquery.Dataset(f"{PROJECT_ID}.{DATASET_ID}")
    dataset_ref.location = "us-central1"
    try:
        client.get_dataset(dataset_ref)
        print(f"Dataset {DATASET_ID} exists.")
    except NotFound:
        print(f"Creating dataset {DATASET_ID} in us-central1...")
        client.create_dataset(dataset_ref, timeout=30)
        print(f"Dataset {DATASET_ID} created successfully.")

    # 2. Generate 500 rows
    print("Generating 500 synthetic report records...")
    rows = generate_rows(500)

    # 3. Load to BigQuery table with schema auto-detection
    job_config = bigquery.LoadJobConfig(
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
    )

    print(f"Loading data into {TABLE_ID}...")
    load_job = client.load_table_from_json(rows, TABLE_ID, job_config=job_config)
    load_job.result()  # Wait for completion

    table = client.get_table(TABLE_ID)
    print(f"Success! Loaded {table.num_rows} rows into {TABLE_ID}.")

if __name__ == "__main__":
    main()
