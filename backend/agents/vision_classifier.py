import json
import logging
from typing import Optional
from config import settings
from models.schemas import VisionClassificationResult

logger = logging.getLogger(__name__)

class VisionClassifierAgent:
    """
    Vision Classifier Agent
    Analyzes civic issue photos using Gemini Vision API.
    Identifies issueType (pothole, garbage, streetlight, leakage, road_damage)
    and assesses severity (low, medium, critical).
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY

    async def classify_image(self, photo_url: str) -> VisionClassificationResult:
        if not self.api_key:
            logger.warning("GEMINI_API_KEY not configured. Falling back to rule-based fallback.")
            return VisionClassificationResult(
                issueType="pothole",
                severity="medium",
                confidence=0.85,
                reasoning="Mock analysis: Visual surface depression detected on asphalt."
            )

        try:
            # We can use Google GenAI SDK or structured Prompt
            from google import genai
            client = genai.Client(api_key=self.api_key)

            prompt = """
            You are CivicPulse Vision Classifier Agent. 
            Analyze the civic infrastructure issue shown in the image.
            
            Classify into:
            - issueType: one of ["pothole", "garbage", "streetlight", "leakage", "road_damage"]
            - severity: one of ["low", "medium", "critical"]
            - confidence: float between 0.0 and 1.0
            - reasoning: concise explanation (1-2 sentences)

            Return ONLY valid JSON matching this structure:
            {"issueType": "pothole", "severity": "medium", "confidence": 0.95, "reasoning": "..."}
            """
            
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[prompt, photo_url]
            )
            
            raw_text = response.text.strip()
            # Clean markdown code blocks if returned
            if raw_text.startswith("```"):
                raw_text = raw_text.split("\n", 1)[1].rsplit("\n", 1)[0].strip()
            
            data = json.loads(raw_text)
            return VisionClassificationResult(**data)
        except Exception as e:
            logger.error(f"Gemini Vision classification failed: {e}")
            return VisionClassificationResult(
                issueType="road_damage",
                severity="medium",
                confidence=0.70,
                reasoning=f"Fallback classification due to AI processing error: {e}"
            )

vision_classifier_agent = VisionClassifierAgent()
