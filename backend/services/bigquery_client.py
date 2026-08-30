import logging
from typing import List, Dict, Any, Optional
from google.cloud import bigquery
from config import settings

logger = logging.getLogger(__name__)

class BigQueryClient:
    def __init__(self):
        try:
            self.client = bigquery.Client(project=settings.PROJECT_ID, location=settings.REGION)
        except Exception as e:
            logger.warning(f"Failed to initialize live BigQuery client: {e}. Running in local mock mode.")
            self.client = None

    async def insert_report_event(self, report_data: Dict[str, Any]) -> bool:
        if not self.client:
            return True
        table_id = f"{settings.PROJECT_ID}.{settings.BIGQUERY_DATASET}.reports_stream"
        try:
            errors = self.client.insert_rows_json(table_id, [report_data])
            if errors:
                logger.error(f"BigQuery insert error: {errors}")
                return False
            return True
        except Exception as e:
            logger.error(f"Failed to stream to BigQuery: {e}")
            return False

    async def query_ward_issue_counts(self, ward: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Adheres to Critical Cost Rules:
        - NEVER SELECT *
        - Query specific columns with LIMIT and partition filters
        """
        if not self.client:
            return []
        
        # Explicit column projection only
        query = f"""
            SELECT 
                ward, 
                issueType, 
                COUNT(1) as totalReports,
                AVG(CASE WHEN severity = 'critical' THEN 3.0 WHEN severity = 'medium' THEN 2.0 ELSE 1.0 END) as avgSeverityScore
            FROM `{settings.PROJECT_ID}.{settings.BIGQUERY_DATASET}.reports_stream`
            WHERE createdAt >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
            {"AND ward = @ward" if ward else ""}
            GROUP BY ward, issueType
            ORDER BY totalReports DESC
            LIMIT 50
        """
        try:
            job_config = bigquery.QueryJobConfig(
                query_parameters=[bigquery.ScalarQueryParameter("ward", "STRING", ward)] if ward else []
            )
            query_job = self.client.query(query, job_config=job_config)
            return [dict(row) for row in query_job.result()]
        except Exception as e:
            logger.error(f"BigQuery query failed: {e}")
            return []

bigquery_client = BigQueryClient()
