import logging
import google.generativeai as genai
from config import settings

logger = logging.getLogger(__name__)

class GeminiClient:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        if self.api_key:
            genai.configure(api_key=self.api_key)

    def get_model(self, model_name: str = "gemini-1.5-flash"):
        if settings.GEMINI_API_KEY and not self.api_key:
            self.api_key = settings.GEMINI_API_KEY
            genai.configure(api_key=self.api_key)
        return genai.GenerativeModel(model_name)

gemini_client = GeminiClient()
