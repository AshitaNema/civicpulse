# CivicPulse Project Rules & Knowledge Base

This file sets the standard engineering practices, cost limitations, and architecture guidelines for CivicPulse.

## Core Project Identifiers
- **GCP Project ID:** `civicpulse-507101`
- **Region:** `us-central1`
- **BigQuery Dataset:** `civicpulse_data`
- **Firestore Collections:** `reports`, `departments`, `predictions`

## Critical Cost & Security Rules
- Keep Cloud Run configurations to `max-instances=2` and `memory=512Mi`.
- BigQuery queries MUST list specific columns—never use `SELECT *`.
- Minimize Firestore document operations (keep within free tier <20k writes/day).
- Never hardcode `GEMINI_API_KEY` or GCP credentials. Use `.env` or Secret Manager.
- All services and storage buckets must remain in `us-central1`.

## Code Style Rules
- Flutter: Clean architecture under `lib/` (`constants/`, `models/`, `services/`, `screens/`, `widgets/`).
- Flutter: Wrap all network/Firebase calls with structured `try/catch` and user feedback.
- Python Backend: FastAPI on Cloud Run, modular agents in `backend/agents/`.
