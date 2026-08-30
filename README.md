# CivicPulse 🏛️⚡

> AI-Powered Civic Issue Reporting & Verification Platform
> Powered by Flutter, Google Cloud Multi-Agent AI (Google ADK & Gemini API), Cloud Firestore, and BigQuery.

---

## 📋 Overview
CivicPulse empowers citizens to report civic infrastructure issues (potholes, garbage, streetlights, leakages, and road damage) with real-time AI classification, spatial duplicate detection, automated municipal routing, and before-and-after photo verification.

- **Platform:** Android & iOS (Flutter Frontend)
- **Backend:** Serverless Python Multi-Agent Service on Google Cloud Run
- **Google Cloud Project ID:** `civicpulse-507101`
- **Region:** `us-central1`

---

## 🏗️ Architecture & Pipeline
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

For complete technical diagrams and agent specifications, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 💰 Cost & Free-Tier Rules
1. **Cloud Run:** Keep deployments to `max-instances=2` and `memory=512Mi`.
2. **BigQuery:** Always specify columns explicitly (NEVER use `SELECT *`).
3. **Firestore:** Designed for low writes/reads (<20k writes/day free tier).
4. **Region:** Strictly stay in `us-central1`.
5. **Security:** Never commit API keys or service account keys. Store secrets in `.env`.

---

## 🛠️ Project Structure
```
civicpulse/
├── .agents/                    # Workspace agent rules & customizations
│   └── rules/civicpulse_rules.md
├── AGENTS.md                   # AI Agent guidance & knowledge base
├── ARCHITECTURE.md             # Detailed architecture specifications
├── .env.example                # Flutter frontend environment template
├── lib/                        # Flutter frontend (Clean Architecture)
│   ├── constants/              # App constants, collections, enums
│   ├── models/                 # Report, Department, Prediction models
│   ├── services/               # Firestore & Storage services
│   ├── screens/                # UI screens
│   ├── widgets/                # UI widgets
│   ├── firebase_options.dart   # Firebase configuration
│   └── main.dart               # App entrypoint
├── backend/                    # Python Cloud Run multi-agent backend
│   ├── agents/                 # Multi-agent modules (Vision, Duplicate, Routing, etc.)
│   ├── models/                 # Pydantic schemas
│   ├── services/               # GCP & Firestore service clients
│   ├── config.py               # Environment configuration
│   ├── main.py                 # FastAPI application
│   ├── Dockerfile              # Cloud Run optimized container
│   ├── requirements.txt        # Python dependencies
│   └── .env.example            # Backend environment template
```

---

## 🚀 Getting Started

### 1. Flutter Mobile App
```bash
# Copy environment configuration
cp .env.example .env

# Install Flutter dependencies
flutter pub get

# Run on connected device or simulator
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

# Run FastAPI local development server
uvicorn main:app --reload --port 8080
```
