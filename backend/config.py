import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_ID: str = "civicpulse-507101"
    REGION: str = "us-central1"
    FIRESTORE_DATABASE: str = "(default)"
    BIGQUERY_DATASET: str = "civicpulse_data"
    
    # Secrets & API Keys
    GEMINI_API_KEY: str = ""
    
    # Pub/Sub
    PUBSUB_REPORTS_TOPIC: str = "civicpulse-reports-topic"
    PUBSUB_SCHEDULED_INSIGHTS_TOPIC: str = "civicpulse-insights-topic"
    
    # Server configuration
    PORT: int = 8080
    LOG_LEVEL: str = "info"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
