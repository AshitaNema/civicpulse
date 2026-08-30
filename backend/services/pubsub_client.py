import json
import logging
from typing import Dict, Any
from google.cloud import pubsub_v1
from config import settings

logger = logging.getLogger(__name__)

class PubSubClient:
    def __init__(self):
        try:
            self.publisher = pubsub_v1.PublisherClient()
            self.topic_path = self.publisher.topic_path(settings.PROJECT_ID, settings.PUBSUB_REPORTS_TOPIC)
        except Exception as e:
            logger.warning(f"Failed to initialize PubSub publisher: {e}. Running in local mock mode.")
            self.publisher = None
            self.topic_path = None

    def publish_report_event(self, event_type: str, report_data: Dict[str, Any]) -> bool:
        if not self.publisher or not self.topic_path:
            return True
        try:
            message_payload = json.dumps({
                "eventType": event_type,
                "report": report_data
            }).encode("utf-8")
            future = self.publisher.publish(self.topic_path, data=message_payload)
            future.result(timeout=5.0)
            return True
        except Exception as e:
            logger.error(f"Failed to publish Pub/Sub event: {e}")
            return False

pubsub_client = PubSubClient()
