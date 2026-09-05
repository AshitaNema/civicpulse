import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    GOOGLE_CLOUD_PROJECT: str = os.getenv("GOOGLE_CLOUD_PROJECT", "civicpulse-507101")
    PROJECT_ID: str = os.getenv("GOOGLE_CLOUD_PROJECT", os.getenv("PROJECT_ID", "civicpulse-507101"))
    REGION: str = os.getenv("REGION", "us-central1")
    FIRESTORE_DATABASE: str = os.getenv("FIRESTORE_DATABASE", "(default)")
    BIGQUERY_DATASET: str = os.getenv("BIGQUERY_DATASET", "civicpulse_data")
    
    # Collections
    FIRESTORE_COLLECTION_REPORTS: str = os.getenv("FIRESTORE_COLLECTION_REPORTS", "reports")
    FIRESTORE_COLLECTION_DEPARTMENTS: str = os.getenv("FIRESTORE_COLLECTION_DEPARTMENTS", "departments")
    FIRESTORE_COLLECTION_PREDICTIONS: str = os.getenv("FIRESTORE_COLLECTION_PREDICTIONS", "predictions")

    # Secrets & API Keys
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # Pub/Sub Topics
    PUBSUB_REPORTS_TOPIC: str = os.getenv("PUBSUB_REPORTS_TOPIC", "new-report")
    PUBSUB_RESOLVED_TOPIC: str = os.getenv("PUBSUB_RESOLVED_TOPIC", "report-resolved")
    
    # Server configuration
    PORT: int = int(os.getenv("PORT", "8080"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "info")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
