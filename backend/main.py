import base64
import json
import logging
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from models.schemas import PubSubPushRequest, ReportDocument
from agents.orchestrator import adk_orchestrator
from agents.insight import insight_agent

logging.basicConfig(level=settings.LOG_LEVEL.upper())
logger = logging.getLogger("civicpulse")

app = FastAPI(
    title="CivicPulse Multi-Agent Backend",
    description="Google Cloud Run Serverless Multi-Agent System for Civic Infrastructure Management",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Health"])
async def root():
    return {
        "status": "online",
        "service": "CivicPulse AI Multi-Agent Backend",
        "region": settings.REGION,
        "projectId": settings.PROJECT_ID
    }

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy"}

@app.post("/events/pubsub", status_code=status.HTTP_200_OK, tags=["Events"])
async def handle_pubsub_event(payload: PubSubPushRequest):
    """
    Cloud Pub/Sub Push Subscription Endpoint.
    Decodes the incoming Pub/Sub message and triggers the ADK Orchestrator pipeline.
    """
    try:
        raw_data = base64.b64decode(payload.message.data).decode("utf-8")
        event_body = json.loads(raw_data)
        logger.info(f"Received Pub/Sub event: {event_body.get('eventType')}")

        event_type = event_body.get("eventType", "NEW_REPORT")
        report_data = event_body.get("report", {})

        if event_type == "NEW_REPORT":
            result = await adk_orchestrator.process_new_report(report_data)
            return {"status": "processed", "result": result}
        elif event_type == "VERIFY_RESOLUTION":
            result = await adk_orchestrator.process_resolution_verification(report_data)
            return {"status": "verified", "result": result}
        else:
            logger.warning(f"Unhandled event type: {event_type}")
            return {"status": "ignored"}
    except Exception as e:
        logger.error(f"Failed to process Pub/Sub message: {e}")
        # Return 200/204 to prevent infinite Pub/Sub retries on malformed messages
        return {"status": "error", "error": str(e)}

@app.post("/reports/process", tags=["Reports"])
async def process_report_direct(report: ReportDocument):
    """
    Direct synchronous endpoint for local development or direct Flutter integration.
    """
    result = await adk_orchestrator.process_new_report(report.model_dump())
    return result

@app.post("/insights/cron-trigger", tags=["Insights"])
async def scheduled_insights_trigger():
    """
    Endpoint triggered by Cloud Scheduler to compute ward spatial risk predictions.
    """
    predictions = await insight_agent.generate_ward_risk_predictions()
    return {
        "status": "success",
        "predictionsGenerated": len(predictions),
        "predictions": [p.model_dump() for p in predictions]
    }
