# CivicPulse Knowledge Base & Agent Guidelines

## Project Overview
- **Project Name:** CivicPulse
- **Type:** Flutter mobile app + Google Cloud multi-agent AI backend
- **Platform:** Android + iOS
- **Language:** Dart (Flutter frontend), Python 3.11+ (Cloud Run backend agents)
- **Google Cloud Project ID:** `civicpulse-507101`
- **Default Region:** `us-central1` (All Cloud Run, BigQuery, Pub/Sub, Firestore services)
- **Firestore Region:** `us-central1`
- **BigQuery Dataset:** `civicpulse_data`

---

## Tech Stack
- **Frontend:** Flutter (Dart)
- **Database:** Cloud Firestore (real-time reports + status)
- **Storage:** Cloud Storage for Firebase (photo uploads)
- **AI:** Gemini API via Google AI Studio (vision classification + resolution verification)
- **Agents:** Google ADK (Agent Development Kit) multi-agent architecture
- **DB Orchestration:** MCP Toolbox for Databases
- **Analytics:** BigQuery + BigQuery ML
- **Dashboard:** Looker Studio
- **Backend:** Cloud Run (serverless, max 2 instances)
- **Events:** Pub/Sub
- **Scheduler:** Cloud Scheduler

---

## Critical Cost Rules (Always Free Tier Enforcement)
> [!CAUTION]
> **Strictly adhere to the following rules to ensure zero unplanned cloud billing:**
> 1. **Cloud Run:** Keep `max-instances=2`, `memory=512Mi` on all deployments.
> 2. **BigQuery:** **NEVER** use `SELECT *`. Always specify required columns and apply date/partition filters.
> 3. **Firestore:** Stay strictly under 20,000 writes/day and 50,000 reads/day. Use batching and caching where possible.
> 4. **GCP Region:** All services and buckets must be deployed exclusively in `us-central1`.
> 5. **Gemini API:** Cache duplicate queries, optimize prompt tokens, and never expose keys in client code or repositories.

---

## Architecture Flow
```
Citizen (Flutter app)
  → photos + GPS → Cloud Storage + Firestore
  → Pub/Sub event triggers
  → Cloud Run (ADK orchestrator)
      → Vision Classifier Agent (Gemini Vision API)
      → Duplicate Detection Agent (Firestore geo-query)
      → Routing Agent (department lookup)
      → Verification Agent (Gemini before/after comparison)
      → Insight Agent (BigQuery ML + Cloud Scheduler)
  → BigQuery (analytics + ML forecasting)
  → Looker Studio (public dashboard)
```

---

## Firestore Schema

### Collections
1. `reports/{reportId}` — Citizen reports
2. `departments/{deptId}` — Ward-to-department routing maps
3. `predictions/{predId}` — BigQuery ML risk zone outputs

### Report Document Schema
```typescript
{
  reportId: string,              // Unique report identifier
  citizenId: string,             // Anonymized or authenticated citizen ID
  photoUrl: string,              // Public/Signed URL of initial issue image
  afterPhotoUrl: string | null,  // Resolved photo URL uploaded by dept
  latitude: number,              // GPS latitude
  longitude: number,             // GPS longitude
  ward: string,                  // Municipal ward identifier
  issueType: string,             // "pothole" | "garbage" | "streetlight" | "leakage" | "road_damage"
  severity: string,              // "low" | "medium" | "critical"
  status: string,                // "open" | "in_progress" | "resolved" | "false_closure"
  department: string,            // Assigned department
  isDuplicate: boolean,          // Flagged if duplicate report exists in vicinity
  parentReportId: string | null, // Original report ID if isDuplicate is true
  createdAt: Timestamp,          // Submission timestamp
  resolvedAt: Timestamp | null,  // Resolution timestamp
  verifiedResolution: boolean | null, // AI verified resolution flag
  verificationNotes: string | null    // AI reasoning on verification
}
```

---

## Code Style & Best Practices

### Flutter Frontend (`lib/`)
- Clean architecture with clear separation:
  - `constants/` — All strings, keys, asset paths, and Firestore collection names. **No hardcoded strings.**
  - `models/` — Strongly-typed models with JSON/Firestore serialization.
  - `services/` — Firebase, Cloud Storage, and API integrations with explicit `try/catch` error boundaries.
  - `screens/` — UI screens separated by domain.
  - `widgets/` — Reusable presentation components.
- State management and responsive layouts.
- Secret management via `.env` with `flutter_dotenv` (never commit keys).

### Python Backend (`backend/`)
- **FastAPI** web framework running on Cloud Run.
- **Modular Agents:** Every agent is isolated in its own module inside `backend/agents/`.
- **Pydantic:** Schema validation for all inputs, outputs, and Firestore models.
- **Async/Await:** Non-blocking I/O for Firestore, Storage, Gemini API, and Pub/Sub calls.
- **Safe Secrets:** Loaded via `python-dotenv` and Google Secret Manager.
