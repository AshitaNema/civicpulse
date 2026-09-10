# CivicPulse 🏛️⚡

> **AI-Powered Civic Issue Reporting & Verification Platform**  
> Flutter · Google ADK Multi-Agent · Gemini API · Cloud Firestore · BigQuery

---

## 📋 Overview

CivicPulse empowers citizens to photograph and report civic infrastructure problems (potholes, garbage, broken streetlights, water leakages, road damage) from their phones. A Google Cloud multi-agent AI pipeline automatically:

1. **Classifies** the issue type and severity using Gemini Vision
2. **Detects duplicates** against nearby open reports in Firestore
3. **Routes** the report to the correct municipal department by ward
4. **Verifies** resolution using AI before/after photo comparison
5. **Predicts** future hot-spots with BigQuery ML

| Property | Value |
|---|---|
| **Platform** | Android + iOS (Flutter) |
| **Backend** | Serverless Python on Google Cloud Run |
| **GCP Project** | `civicpulse-507101` |
| **Region** | `us-central1` (all services) |

---

## 🏗️ Architecture

```
Citizen (Flutter app)
  → Camera/Gallery photo + GPS → Cloud Storage + Firestore
  → Pub/Sub event triggers
  → Cloud Run (ADK orchestrator)
      → Vision Classifier Agent (Gemini 1.5 Flash)
      → Duplicate Detection Agent (Firestore geo-query)
      → Routing Agent (department lookup)
      → Verification Agent (Gemini before/after comparison)
      → Insight Agent (BigQuery ML + Cloud Scheduler)
  → BigQuery (analytics + ML forecasting)
  → Looker Studio (public dashboard)
```

For full Mermaid diagrams, agent tables, Firestore schemas, and deployment commands → **[ARCHITECTURE.md](ARCHITECTURE.md)**

---

## 📁 Project Structure

```
civicpulse/
├── AGENTS.md                    # AI agent guidance & project knowledge base
├── ARCHITECTURE.md              # Full architecture with Mermaid diagrams
├── .env.example                 # Flutter frontend environment template
│
├── lib/                         # Flutter frontend (Clean Architecture)
│   ├── constants/               # Firestore collection names, enums, string constants
│   ├── models/                  # Report, Department, Prediction — typed Firestore models
│   ├── services/
│   │   ├── gemini_service.dart  # Gemini Vision API — issue classification
│   │   ├── firestore_service.dart # Firestore CRUD + agent pipeline trigger
│   │   └── storage_service.dart # Firebase Storage — photo upload/download
│   ├── screens/
│   │   ├── home_screen.dart     # Landing page
│   │   ├── report_screen.dart   # Photo capture (Camera/Gallery), AI classify, submit
│   │   ├── success_screen.dart  # Report confirmation with AI result
│   │   └── reports_list_screen.dart # Real-time report list + verification upload
│   ├── widgets/                 # Reusable UI components
│   ├── firebase_options.dart    # FlutterFire generated config
│   └── main.dart                # App entrypoint
│
└── backend/                     # Python Cloud Run multi-agent service
    ├── agents/
    │   ├── orchestrator.py      # Google ADK pipeline coordinator
    │   ├── vision_classifier.py # Gemini Vision classification
    │   ├── duplicate_detection.py # Geo-radius duplicate check
    │   ├── routing.py           # Ward-to-department routing
    │   ├── verification.py      # Before/after photo verification
    │   └── insight.py           # BigQuery ML hot-spot scoring
    ├── services/
    │   ├── firestore_client.py  # Async Firestore client
    │   ├── gemini_client.py     # Gemini API client with prompt caching
    │   └── bigquery_client.py   # BigQuery parameterized queries
    ├── models/                  # Pydantic request/response schemas
    ├── config.py                # Environment variable loader
    ├── main.py                  # FastAPI app — 3 webhooks + /health
    ├── Dockerfile               # Cloud Run optimised container
    ├── requirements.txt         # Python dependencies
    └── .env.example             # Backend environment template
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- Python 3.11+
- Google Cloud CLI (`gcloud`)
- Firebase CLI (for `firebase_options.dart` generation)

### 1. Flutter Mobile App

```bash
# Copy environment variables
cp .env.example .env
# Edit .env and set GEMINI_API_KEY and API_BASE_URL

# Install Flutter dependencies
flutter pub get

# Run on a connected device or simulator
flutter run
```

### 2. Python Cloud Run Backend

```bash
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy backend environment template
cp .env.example .env
# Edit .env: GEMINI_API_KEY, GOOGLE_CLOUD_PROJECT, BIGQUERY_DATASET, etc.

# Run FastAPI local development server
uvicorn main:app --reload --port 8080
```

### 3. Deploy to Cloud Run

```bash
gcloud run deploy civicpulse-backend \
  --source backend/ \
  --region us-central1 \
  --max-instances 2 \
  --memory 512Mi \
  --project civicpulse-507101
```

---

## 🔑 Environment Variables

### Flutter Frontend (`.env`)

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google AI Studio API key |
| `API_BASE_URL` | Cloud Run backend URL |

### Python Backend (`backend/.env`)

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google AI Studio API key |
| `GOOGLE_CLOUD_PROJECT` | GCP project ID |
| `FIRESTORE_DATABASE` | Firestore database ID |
| `BIGQUERY_DATASET` | BigQuery dataset (`civicpulse_data`) |

> **Security:** Never commit `.env` files. Always use `.env.example` as the committed template.

---

## 🐛 Debugging

### Trigger pipeline manually (in-app)

Open the **Reports** screen and tap the **🐛 Debug Pipeline** floating button.  
It fetches the most recent Firestore report and fires `triggerAgentPipeline` — watch Flutter debug console for `[DEBUG FAB]` and `[FirestoreService]` logs.

### Check Cloud Run logs

```bash
gcloud run services logs read civicpulse-backend \
  --region us-central1 \
  --project civicpulse-507101 \
  --limit 30
```

---

## 💰 Cost & Free-Tier Rules

| Service | Rule |
|---|---|
| **Cloud Run** | `max-instances=2`, `memory=512Mi` |
| **BigQuery** | Always name columns — never `SELECT *`; apply date/partition filters |
| **Firestore** | < 20 000 writes/day; < 50 000 reads/day; batch + cache |
| **Region** | Strictly `us-central1` for every service and bucket |
| **Secrets** | Never commit API keys; store in `.env` or Google Secret Manager |

---

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — Full system diagrams, agent specs, Firestore schema, deployment commands
- [AGENTS.md](AGENTS.md) — Project knowledge base and AI agent coding guidelines
