"""
FastAPI application for Heart Disease Prediction API.

Endpoints:
- GET /health: Health check
- GET /: API info
- POST /predict: Make prediction
- GET /metrics: Prometheus metrics
"""

import sys
import time
import logging
from datetime import datetime
from typing import Optional
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

# Add project root to path for imports
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from src.models.predict import HeartDiseasePredictor, FEATURE_SCHEMA  # noqa: E402


# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Prometheus metrics
PREDICTIONS_TOTAL = Counter(
    "predictions_total", "Total number of predictions made", ["result"]
)
PREDICTION_LATENCY = Histogram(
    "prediction_latency_seconds", "Prediction latency in seconds"
)
REQUEST_COUNT = Counter(
    "request_count_total", "Total request count", ["method", "endpoint", "status"]
)

# Initialize FastAPI app
app = FastAPI(
    title="Heart Disease Prediction API",
    description="ML-powered API to predict heart disease risk based on patient health data",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global predictor instance
predictor: Optional[HeartDiseasePredictor] = None


class PatientFeatures(BaseModel):
    """Input schema for patient features."""

    age: int = Field(..., ge=0, le=120, description="Age in years")
    sex: int = Field(..., ge=0, le=1, description="Sex (1 = male, 0 = female)")
    cp: int = Field(..., ge=0, le=3, description="Chest pain type (0-3)")
    trestbps: int = Field(
        ..., ge=50, le=250, description="Resting blood pressure (mm Hg)"
    )
    chol: int = Field(..., ge=100, le=600, description="Serum cholesterol (mg/dl)")
    fbs: int = Field(
        ..., ge=0, le=1, description="Fasting blood sugar > 120 mg/dl (1=true, 0=false)"
    )
    restecg: int = Field(..., ge=0, le=2, description="Resting ECG results (0-2)")
    thalach: int = Field(..., ge=50, le=250, description="Maximum heart rate achieved")
    exang: int = Field(
        ..., ge=0, le=1, description="Exercise induced angina (1=yes, 0=no)"
    )
    oldpeak: float = Field(
        ..., ge=0, le=10, description="ST depression induced by exercise"
    )
    slope: int = Field(
        ..., ge=0, le=2, description="Slope of peak exercise ST segment (0-2)"
    )
    ca: int = Field(
        ...,
        ge=0,
        le=4,
        description="Number of major vessels colored by fluoroscopy (0-4)",
    )
    thal: int = Field(..., ge=0, le=3, description="Thalassemia (0-3)")

    class Config:
        json_schema_extra = {
            "example": {
                "age": 63,
                "sex": 1,
                "cp": 3,
                "trestbps": 145,
                "chol": 233,
                "fbs": 1,
                "restecg": 0,
                "thalach": 150,
                "exang": 0,
                "oldpeak": 2.3,
                "slope": 0,
                "ca": 0,
                "thal": 1,
            }
        }


class PredictionResponse(BaseModel):
    """Output schema for predictions."""

    prediction: int = Field(..., description="0 = No Disease, 1 = Disease")
    prediction_label: str = Field(..., description="Human-readable prediction")
    probability_no_disease: float = Field(
        ..., description="Probability of no heart disease"
    )
    probability_disease: float = Field(..., description="Probability of heart disease")
    confidence: float = Field(..., description="Confidence score (max probability)")
    timestamp: str = Field(..., description="Prediction timestamp")


class HealthResponse(BaseModel):
    """Health check response."""

    model_config = {"protected_namespaces": ()}  # Allow model_ prefix

    status: str
    model_loaded: bool
    timestamp: str


@app.on_event("startup")
async def startup_event():
    """Load model on startup."""
    global predictor
    try:
        # Try different paths for model loading
        model_paths = [
            ("models/best_model.joblib", "models/preprocessing_pipeline.joblib"),
            (
                "/app/models/best_model.joblib",
                "/app/models/preprocessing_pipeline.joblib",
            ),
        ]

        for model_path, pipeline_path in model_paths:
            if Path(model_path).exists() and Path(pipeline_path).exists():
                predictor = HeartDiseasePredictor(model_path, pipeline_path)
                logger.info(f"Model loaded successfully from {model_path}")
                return

        logger.warning(
            "Model not found. API will return errors until model is available."
        )
    except Exception as e:
        logger.error(f"Failed to load model: {e}")


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Middleware to log all requests."""
    start_time = time.time()

    response = await call_next(request)

    process_time = time.time() - start_time

    # Log request
    logger.info(
        f"{request.method} {request.url.path} "
        f"status={response.status_code} "
        f"duration={process_time:.3f}s"
    )

    # Update metrics
    REQUEST_COUNT.labels(
        method=request.method, endpoint=request.url.path, status=response.status_code
    ).inc()

    return response


@app.get("/", tags=["Info"])
async def root():
    """API information endpoint."""
    return {
        "name": "Heart Disease Prediction API",
        "version": "1.0.0",
        "description": "Predict heart disease risk based on patient health data",
        "endpoints": {
            "/health": "Health check",
            "/predict": "Make prediction (POST)",
            "/docs": "API documentation",
            "/metrics": "Prometheus metrics",
        },
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy" if predictor is not None else "degraded",
        model_loaded=predictor is not None,
        timestamp=datetime.utcnow().isoformat(),
    )


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
async def predict(features: PatientFeatures):
    """
    Make a heart disease prediction.

    Accepts patient health features and returns prediction with probability scores.
    """
    if predictor is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please ensure model artifacts are available.",
        )

    try:
        start_time = time.time()

        # Convert to dict and predict
        features_dict = features.model_dump()
        result = predictor.predict(features_dict)

        # Record latency
        latency = time.time() - start_time
        PREDICTION_LATENCY.observe(latency)

        # Update prediction counter
        label = "disease" if result["prediction"] == 1 else "no_disease"
        PREDICTIONS_TOTAL.labels(result=label).inc()

        # Log prediction
        logger.info(
            f"Prediction: {result['prediction_label']} "
            f"(confidence: {result['confidence']:.3f}, latency: {latency:.3f}s)"
        )

        return PredictionResponse(
            prediction=result["prediction"],
            prediction_label=result["prediction_label"],
            probability_no_disease=result["probability_no_disease"],
            probability_disease=result["probability_disease"],
            confidence=result["confidence"],
            timestamp=datetime.utcnow().isoformat(),
        )

    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/metrics", tags=["Monitoring"])
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/schema", tags=["Info"])
async def get_schema():
    """Get the feature schema with descriptions."""
    return FEATURE_SCHEMA


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
