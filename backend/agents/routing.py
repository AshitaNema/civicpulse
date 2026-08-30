import logging
from typing import Optional
from services.firestore_client import firestore_client
from models.schemas import RoutingResult

logger = logging.getLogger(__name__)

# Fallback department mapping rules
DEFAULT_DEPARTMENT_MAPPING = {
    "pothole": "Roads & Highway Maintenance",
    "road_damage": "Roads & Highway Maintenance",
    "garbage": "Solid Waste & Sanitation Management",
    "streetlight": "Electrical & Public Lighting",
    "leakage": "Water Supply & Sewerage Board",
}

class RoutingAgent:
    """
    Routing Agent
    Determines municipal department ownership based on ward coverage and issue category.
    """

    async def route_report(self, ward: str, issue_type: str) -> RoutingResult:
        try:
            dept_data = await firestore_client.get_department_for_ward(ward=ward, category=issue_type)
            if dept_data:
                return RoutingResult(
                    department=dept_data.get("name", DEFAULT_DEPARTMENT_MAPPING.get(issue_type, "Public Works")),
                    contactEmail=dept_data.get("contactEmail")
                )
            
            # Default fallback routing
            dept_name = DEFAULT_DEPARTMENT_MAPPING.get(issue_type, "General Public Works")
            return RoutingResult(department=dept_name)
        except Exception as e:
            logger.error(f"Routing failed: {e}")
            return RoutingResult(department=DEFAULT_DEPARTMENT_MAPPING.get(issue_type, "General Public Works"))

routing_agent = RoutingAgent()
