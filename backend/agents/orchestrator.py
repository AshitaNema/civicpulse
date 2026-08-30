import logging
from typing import Dict, Any
from .vision_classifier import vision_classifier_agent
from .duplicate_detection import duplicate_detection_agent
from .routing import routing_agent
from .verification import verification_agent
from services.firestore_client import firestore_client
from services.bigquery_client import bigquery_client

logger = logging.getLogger(__name__)

class ADKOrchestrator:
    """
    ADK Orchestrator
    Coordinates the multi-agent execution pipeline on Cloud Run:
    1. Vision Classification (Gemini API)
    2. Duplicate Detection (Geo-spatial search)
    3. Department Routing (Ward mapping)
    4. Resolution Verification (Before/After analysis)
    5. BigQuery Event Streaming (Analytics)
    """

    async def process_new_report(self, report_data: Dict[str, Any]) -> Dict[str, Any]:
        report_id = report_data.get("reportId", "")
        photo_url = report_data.get("photoUrl", "")
        latitude = float(report_data.get("latitude", 0.0))
        longitude = float(report_data.get("longitude", 0.0))
        ward = report_data.get("ward", "Ward-01")

        logger.info(f"[Orchestrator] Processing new report {report_id}")
        updates: Dict[str, Any] = {}

        # 1. Vision Classifier Agent
        if photo_url:
            classification = await vision_classifier_agent.classify_image(photo_url)
            updates["issueType"] = classification.issueType
            updates["severity"] = classification.severity
            issue_type = classification.issueType
        else:
            issue_type = report_data.get("issueType", "pothole")

        # 2. Duplicate Detection Agent
        duplicate_check = await duplicate_detection_agent.check_duplicate(
            report_id=report_id,
            latitude=latitude,
            longitude=longitude,
            issue_type=issue_type
        )
        updates["isDuplicate"] = duplicate_check.isDuplicate
        if duplicate_check.isDuplicate:
            updates["parentReportId"] = duplicate_check.parentReportId
            logger.info(f"[DuplicateAgent] Report {report_id} flagged as duplicate of {duplicate_check.parentReportId}")

        # 3. Routing Agent
        routing_result = await routing_agent.route_report(ward=ward, issue_type=issue_type)
        updates["department"] = routing_result.department

        # 4. Commit updates to Firestore
        if report_id:
            await firestore_client.update_report(report_id, updates)

        # 5. Stream event to BigQuery
        merged_report = {**report_data, **updates}
        await bigquery_client.insert_report_event(merged_report)

        return merged_report

    async def process_resolution_verification(self, report_data: Dict[str, Any]) -> Dict[str, Any]:
        report_id = report_data.get("reportId", "")
        photo_url = report_data.get("photoUrl", "")
        after_photo_url = report_data.get("afterPhotoUrl", "")
        issue_type = report_data.get("issueType", "pothole")

        logger.info(f"[Orchestrator] Processing resolution verification for {report_id}")
        
        verification = await verification_agent.verify_resolution(
            before_photo_url=photo_url,
            after_photo_url=after_photo_url,
            issue_type=issue_type
        )

        updates = {
            "verifiedResolution": verification.verifiedResolution,
            "verificationNotes": verification.verificationNotes,
            "status": "resolved" if verification.verifiedResolution else "false_closure"
        }

        if report_id:
            await firestore_client.update_report(report_id, updates)

        return {**report_data, **updates}

adk_orchestrator = ADKOrchestrator()
