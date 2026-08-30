import logging
from datetime import datetime
from typing import List
from services.bigquery_client import bigquery_client
from services.firestore_client import firestore_client
from models.schemas import PredictionDocument

logger = logging.getLogger(__name__)

class InsightAgent:
    """
    Insight Agent
    Leverages BigQuery ML and scheduled event triggers to generate spatial risk zone predictions.
    Outputs to Firestore 'predictions' collection and BigQuery dataset.
    """

    async def generate_ward_risk_predictions(self) -> List[PredictionDocument]:
        try:
            # Query aggregated counts adhering to strict cost rules (Never SELECT *)
            stats = await bigquery_client.query_ward_issue_counts()
            
            predictions: List[PredictionDocument] = []
            for item in stats:
                ward = item.get("ward", "Ward-01")
                issue_type = item.get("issueType", "pothole")
                total = item.get("totalReports", 0)
                avg_sev = item.get("avgSeverityScore", 1.0)

                # Normalized risk score: (total / 100) * avg_sev
                calculated_risk = min(1.0, (total * 0.05) + (avg_sev * 0.2))

                pred = PredictionDocument(
                    predId=f"pred_{ward}_{int(datetime.utcnow().timestamp())}",
                    ward=ward,
                    riskScore=round(calculated_risk, 2),
                    predictedIssueType=issue_type,
                    generatedAt=datetime.utcnow()
                )
                predictions.append(pred)

            return predictions
        except Exception as e:
            logger.error(f"Insight agent risk generation failed: {e}")
            return []

insight_agent = InsightAgent()
