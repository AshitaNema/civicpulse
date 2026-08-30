import math
import logging
from typing import Optional
from services.firestore_client import firestore_client
from models.schemas import DuplicateDetectionResult

logger = logging.getLogger(__name__)

def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000  # Radius of Earth in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2.0) ** 2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

class DuplicateDetectionAgent:
    """
    Duplicate Detection Agent
    Performs geo-spatial proximity queries on Firestore to flag duplicated citizen reports.
    """

    DUPLICATE_RADIUS_THRESHOLD_METERS = 50.0  # 50 meters

    async def check_duplicate(
        self,
        report_id: str,
        latitude: float,
        longitude: float,
        issue_type: str
    ) -> DuplicateDetectionResult:
        try:
            nearby = await firestore_client.find_nearby_reports(
                latitude=latitude,
                longitude=longitude,
                issue_type=issue_type,
                exclude_report_id=report_id
            )

            closest_distance = None
            parent_id = None

            for report in nearby:
                # Only compare against active reports
                if report.get("status") in ["open", "in_progress"]:
                    rep_lat = report.get("latitude", 0.0)
                    rep_lng = report.get("longitude", 0.0)
                    dist = haversine_distance_meters(latitude, longitude, rep_lat, rep_lng)

                    if dist <= self.DUPLICATE_RADIUS_THRESHOLD_METERS:
                        if closest_distance is None or dist < closest_distance:
                            closest_distance = dist
                            parent_id = report.get("reportId", report.get("id"))

            if parent_id:
                return DuplicateDetectionResult(
                    isDuplicate=True,
                    parentReportId=parent_id,
                    distanceMeters=closest_distance
                )
            
            return DuplicateDetectionResult(isDuplicate=False)
        except Exception as e:
            logger.error(f"Duplicate detection failed: {e}")
            return DuplicateDetectionResult(isDuplicate=False)

duplicate_detection_agent = DuplicateDetectionAgent()
