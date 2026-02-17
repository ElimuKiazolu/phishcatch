from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
from risk_engine import analyze_text
from config import settings

app = FastAPI(
    title=settings.APP_NAME,
    description="Explainable phishing and scam detection API",
    version=settings.VERSION
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict later in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ScanRequest(BaseModel):
    content: str

class ScanResponse(BaseModel):
    risk_score: int
    risk_level: str
    indicators: List[str]
    advice: str

@app.get("/")
def root():
    return {
        "message": f"{settings.APP_NAME} is running",
        "environment": settings.ENVIRONMENT
    }

@app.post("/analyze", response_model=ScanResponse)
def analyze(scan: ScanRequest):
    result = analyze_text(scan.content)
    return result
