from datetime import datetime
from typing import Optional, List, Literal
from pydantic import BaseModel, Field

# Supported enumerations
IssueTypeLiteral = Literal["pothole", "garbage", "streetlight", "leakage", "road_damage"]
SeverityLiteral = Literal["low", "medium", "critical"]
StatusLiteral = Literal["open", "in_progress", "resolved", "false_closure"]

class ReportDocument(BaseModel):
    reportId: str
    citizenId: str
    photoUrl: str
    afterPhotoUrl: Optional[str] = None
    latitude: float
    longitude: float
    ward: str
    issueType: IssueTypeLiteral = "pothole"
    severity: SeverityLiteral = "low"
    status: StatusLiteral = "open"
    department: str = "unassigned"
    isDuplicate: bool = False
    parentReportId: Optional[str] = None
    createdAt: datetime = Field(default_factory=datetime.utcnow)
    resolvedAt: Optional[datetime] = None
    verifiedResolution: Optional[bool] = None
    verificationNotes: Optional[str] = None

class DepartmentDocument(BaseModel):
    deptId: str
    name: str
    contactEmail: str
    wardCoverage: List[str] = []
    supportedCategories: List[str] = []

class PredictionDocument(BaseModel):
    predId: str
    ward: str
    riskScore: float
    predictedIssueType: str
    generatedAt: datetime = Field(default_factory=datetime.utcnow)

# Agent Input / Output Schemas
class VisionClassificationResult(BaseModel):
    issueType: IssueTypeLiteral
    severity: SeverityLiteral
    confidence: float
    reasoning: str

class DuplicateDetectionResult(BaseModel):
    isDuplicate: bool
    parentReportId: Optional[str] = None
    distanceMeters: Optional[float] = None

class RoutingResult(BaseModel):
    department: str
    contactEmail: Optional[str] = None

class VerificationResult(BaseModel):
    verifiedResolution: bool
    confidence: float
    verificationNotes: str

# Pub/Sub Payload Envelopes
class PubSubMessage(BaseModel):
    data: str
    messageId: Optional[str] = None
    publishTime: Optional[str] = None

class PubSubPushRequest(BaseModel):
    message: PubSubMessage
    subscription: Optional[str] = None
