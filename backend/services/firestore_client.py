import logging
from typing import Optional, List, Dict, Any
from google.cloud import firestore
from config import settings

logger = logging.getLogger(__name__)

class FirestoreClient:
    def __init__(self):
        try:
            self.db = firestore.Client(project=settings.PROJECT_ID, database=settings.FIRESTORE_DATABASE)
        except Exception as e:
            logger.warning(f"Failed to initialize live Firestore client: {e}. Running in local mock mode.")
            self.db = None

    async def get_report(self, report_id: str) -> Optional[Dict[str, Any]]:
        if not self.db:
            return None
        doc = self.db.collection("reports").document(report_id).get()
        return doc.to_dict() if doc.exists else None

    async def update_report(self, report_id: str, updates: Dict[str, Any]) -> bool:
        if not self.db:
            return True
        try:
            self.db.collection("reports").document(report_id).update(updates)
            return True
        except Exception as e:
            logger.error(f"Error updating report {report_id}: {e}")
            return False

    async def find_nearby_reports(
        self,
        latitude: float,
        longitude: float,
        issue_type: str,
        radius_degrees: float = 0.0005, # Approx 50 meters
        exclude_report_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Geographic box query bounded to minimize Firestore reads (under free-tier limit).
        """
        if not self.db:
            return []
        try:
            min_lat = latitude - radius_degrees
            max_lat = latitude + radius_degrees
            min_lng = longitude - radius_degrees
            max_lng = longitude + radius_degrees

            query = (
                self.db.collection("reports")
                .where("issueType", "==", issue_type)
                .where("latitude", ">=", min_lat)
                .where("latitude", "<=", max_lat)
                .limit(10)
            )

            results = []
            for doc in query.stream():
                data = doc.to_dict()
                if exclude_report_id and doc.id == exclude_report_id:
                    continue
                # Bounding box filter for longitude
                if min_lng <= data.get("longitude", 0.0) <= max_lng:
                    data["reportId"] = doc.id
                    results.append(data)
            return results
        except Exception as e:
            logger.error(f"Error finding nearby reports: {e}")
            return []

    async def get_department_for_ward(self, ward: str, category: str) -> Optional[Dict[str, Any]]:
        if not self.db:
            return {"deptId": "dept_default", "name": "General Public Works"}
        try:
            query = (
                self.db.collection("departments")
                .where("wardCoverage", "array_contains", ward)
                .limit(5)
            )
            for doc in query.stream():
                data = doc.to_dict()
                if category in data.get("supportedCategories", []):
                    return data
            return {"deptId": "dept_public_works", "name": "Municipal Public Works"}
        except Exception as e:
            logger.error(f"Error fetching department for ward {ward}: {e}")
            return None

firestore_client = FirestoreClient()
