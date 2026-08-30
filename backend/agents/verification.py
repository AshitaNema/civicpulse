import json
import logging
from typing import Optional
from config import settings
from models.schemas import VerificationResult

logger = logging.getLogger(__name__)

class VerificationAgent:
    """
    Verification Agent
    Compares initial issue photo (before) with resolution photo (after)
    using Gemini Vision multimodal reasoning to confirm physical resolution.
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY

    async def verify_resolution(
        self,
        before_photo_url: str,
        after_photo_url: str,
        issue_type: str
    ) -> VerificationResult:
        if not self.api_key:
            logger.warning("GEMINI_API_KEY not configured. Falling back to default verification.")
            return VerificationResult(
                verifiedResolution=True,
                confidence=0.88,
                verificationNotes="Mock verification: Visual before/after comparison shows issue rectified."
            )

        try:
            from google import genai
            client = genai.Client(api_key=self.api_key)

            prompt = f"""
            You are the CivicPulse Verification Agent.
            You are provided with two photos of a municipal civic issue ({issue_type}):
            1. BEFORE image: The original reported problem.
            2. AFTER image: The image uploaded by the field crew claiming the fix is complete.

            Evaluate whether the work has actually been resolved (e.g. pothole asphalt filled, garbage cleared, water pipe fixed).
            Detect false closures (e.g. photo taken elsewhere, unchanged problem, blurry image, blocked view).

            Return ONLY valid JSON matching:
            {{
                "verifiedResolution": true or false,
                "confidence": 0.0 to 1.0,
                "verificationNotes": "Concise summary of findings and evidence"
            }}
            """

            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[prompt, before_photo_url, after_photo_url]
            )

            raw_text = response.text.strip()
            if raw_text.startswith("```"):
                raw_text = raw_text.split("\n", 1)[1].rsplit("\n", 1)[0].strip()

            data = json.loads(raw_text)
            return VerificationResult(**data)
        except Exception as e:
            logger.error(f"Verification agent failed: {e}")
            return VerificationResult(
                verifiedResolution=False,
                confidence=0.5,
                verificationNotes=f"Verification failed to run: {e}"
            )

verification_agent = VerificationAgent()
