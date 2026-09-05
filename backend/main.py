import base64
import json
import logging
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from agents.duplicate_detection import duplicate_detection_agent
from agents.routing import routing_agent
from agents.verification import verification_agent
from agents.insight import insight_agent
from services.firestore_client import firestore_client

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

def decode_pubsub(request_body: dict) -> dict:
    message = request_body.get('message', {})
    data = message.get('data', '')
    if not data:
        return {}
    decoded = base64.b64decode(data).decode('utf-8')
    return json.loads(decoded)

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok"}

@app.get("/", tags=["Health"])
async def root():
    return {
        "status": "ok",
        "service": "CivicPulse AI Multi-Agent Backend",
        "region": settings.REGION,
        "projectId": settings.PROJECT_ID
    }

@app.post("/webhook/new-report", status_code=status.HTTP_200_OK, tags=["Webhooks"])
async def handle_new_report(request: Request):
    """
    POST /webhook/new-report
    Decodes Pub/Sub base64 message -> runs DuplicateAgent then RoutingAgent in sequence -> returns HTTP 200 always.
    """
    try:
        body = await request.json()
        report_data = decode_pubsub(body)
        logger.info(f"Received /webhook/new-report: {report_data}")

        report_id = report_data.get("reportId", "")
        latitude = float(report_data.get("latitude", 0.0))
        longitude = float(report_data.get("longitude", 0.0))
        issue_type = report_data.get("issueType", "pothole")
        ward = report_data.get("ward", "Ward_1")

        updates = {}

        # 1. Duplicate Detection Agent
        dup_result = await duplicate_detection_agent.check_duplicate(
            report_id=report_id,
            latitude=latitude,
            longitude=longitude,
            issue_type=issue_type,
        )
        updates["isDuplicate"] = dup_result.isDuplicate
        if dup_result.isDuplicate:
            updates["parentReportId"] = dup_result.parentReportId

        # 2. Routing Agent
        route_result = await routing_agent.route_report(
            ward=ward,
            issue_type=issue_type,
        )
        updates["department"] = route_result.department

        # Update Firestore
        if report_id:
            await firestore_client.update_report(report_id, updates)

        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ok", "updates": updates})
    except Exception as e:
        logger.error(f"Error in /webhook/new-report: {e}")
        # Always return HTTP 200 to avoid Pub/Sub retry storms
        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ok", "error": str(e)})

@app.post("/webhook/report-resolved", status_code=status.HTTP_200_OK, tags=["Webhooks"])
async def handle_report_resolved(request: Request):
    """
    POST /webhook/report-resolved
    Decodes Pub/Sub base64 message -> runs VerificationAgent -> returns HTTP 200 always.
    """
    try:
        body = await request.json()
        report_data = decode_pubsub(body)
        logger.info(f"Received /webhook/report-resolved: {report_data}")

        result = await verification_agent.verify_report(report_data)
        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ok", "result": result})
    except Exception as e:
        logger.error(f"Error in /webhook/report-resolved: {e}")
        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ok", "error": str(e)})

@app.post("/webhook/daily-insight", status_code=status.HTTP_200_OK, tags=["Webhooks"])
async def handle_daily_insight(request: Request):
    """
    POST /webhook/daily-insight
    Runs InsightAgent -> returns HTTP 200 always.
    """
    try:
        predictions = await insight_agent.generate_daily_insights()
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"status": "ok", "predictionsCount": len(predictions)}
        )
    except Exception as e:
        logger.error(f"Error in /webhook/daily-insight: {e}")
        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ok", "error": str(e)})
