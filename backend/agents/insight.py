import logging
from datetime import datetime
from google.cloud import firestore
from services.bigquery_client import bigquery_client
from services.firestore_client import firestore_client

logger = logging.getLogger(__name__)

class InsightAgent:
    """
    Insight Agent
    - Queries BigQuery civicpulse_data.reports for ward risk statistics
    - Writes top 3 risk insights to Firestore predictions collection
    """

    async def generate_daily_insights(self) -> list:
        try:
            # 1. Query BigQuery for top report counts and false closure statistics
            results = await bigquery_client.query_top_issue_insights()
            logger.info(f"BigQuery insight results fetched: {len(results)} rows")

            # 2. Extract top 3 results
            top_3 = results[:3]
            saved_predictions = []

            for index, item in enumerate(top_3):
                ward = item.get("ward", f"Ward_{index + 1}")
                issue_type = item.get("issue_type", "pothole")
                report_count = item.get("report_count", 0)
                pred_id = f"pred_{ward.lower()}_{int(datetime.utcnow().timestamp())}_{index}"

                prediction_doc = {
                    "ward": ward,
                    "risk_level": "high",
                    "top_issue_type": issue_type,
                    "report_count": report_count,
                    "generated_at": firestore.SERVER_TIMESTAMP if firestore_client.db else datetime.utcnow().isoformat()
                }

                await firestore_client.write_prediction(pred_id, prediction_doc)
                saved_predictions.append({"predictionId": pred_id, **prediction_doc})

            logger.info(f"Successfully saved {len(saved_predictions)} predictions to Firestore")
            return saved_predictions

        except Exception as e:
            logger.error(f"Error generating daily insights: {e}")
            return []

insight_agent = InsightAgent()
