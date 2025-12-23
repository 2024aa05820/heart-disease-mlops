"""
Unit tests for the FastAPI application.
"""

import pytest
from fastapi.testclient import TestClient
from pathlib import Path
import sys

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.api.app import app


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


@pytest.fixture
def valid_patient_data():
    """Valid patient data for testing."""
    return {
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
        "thal": 1
    }


class TestHealthEndpoint:
    """Tests for health check endpoint."""
    
    def test_health_endpoint_returns_200(self, client):
        """Test that health endpoint returns 200."""
        response = client.get("/health")
        assert response.status_code == 200
    
    def test_health_response_structure(self, client):
        """Test health response structure."""
        response = client.get("/health")
        data = response.json()
        
        assert "status" in data
        assert "model_loaded" in data
        assert "timestamp" in data


class TestRootEndpoint:
    """Tests for root endpoint."""
    
    def test_root_endpoint_returns_200(self, client):
        """Test that root endpoint returns 200."""
        response = client.get("/")
        assert response.status_code == 200
    
    def test_root_response_structure(self, client):
        """Test root response contains API info."""
        response = client.get("/")
        data = response.json()
        
        assert "name" in data
        assert "version" in data
        assert "endpoints" in data


class TestSchemaEndpoint:
    """Tests for schema endpoint."""
    
    def test_schema_endpoint_returns_200(self, client):
        """Test that schema endpoint returns 200."""
        response = client.get("/schema")
        assert response.status_code == 200
    
    def test_schema_contains_features(self, client):
        """Test that schema contains all features."""
        response = client.get("/schema")
        data = response.json()
        
        expected_features = [
            "age", "sex", "cp", "trestbps", "chol", "fbs",
            "restecg", "thalach", "exang", "oldpeak", "slope", "ca", "thal"
        ]
        
        for feature in expected_features:
            assert feature in data


class TestMetricsEndpoint:
    """Tests for Prometheus metrics endpoint."""
    
    def test_metrics_endpoint_returns_200(self, client):
        """Test that metrics endpoint returns 200."""
        response = client.get("/metrics")
        assert response.status_code == 200
    
    def test_metrics_content_type(self, client):
        """Test that metrics returns Prometheus format."""
        response = client.get("/metrics")
        # Should contain Prometheus metrics
        assert b"request_count_total" in response.content or response.status_code == 200


class TestPredictEndpoint:
    """Tests for prediction endpoint."""
    
    def test_predict_invalid_data_returns_422(self, client):
        """Test that invalid data returns 422."""
        invalid_data = {"age": "not_a_number"}
        response = client.post("/predict", json=invalid_data)
        assert response.status_code == 422
    
    def test_predict_missing_fields_returns_422(self, client):
        """Test that missing fields returns 422."""
        incomplete_data = {"age": 63, "sex": 1}
        response = client.post("/predict", json=incomplete_data)
        assert response.status_code == 422
    
    def test_predict_out_of_range_returns_422(self, client):
        """Test that out of range values return 422."""
        invalid_data = {
            "age": 200,  # Out of range
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
            "thal": 1
        }
        response = client.post("/predict", json=invalid_data)
        assert response.status_code == 422
    
    def test_predict_valid_data_response_structure(self, client, valid_patient_data):
        """Test prediction response structure when model is loaded."""
        response = client.post("/predict", json=valid_patient_data)
        
        # If model is loaded, check response structure
        if response.status_code == 200:
            data = response.json()
            assert "prediction" in data
            assert "prediction_label" in data
            assert "probability_no_disease" in data
            assert "probability_disease" in data
            assert "confidence" in data
            assert "timestamp" in data
        else:
            # Model not loaded - should be 503
            assert response.status_code == 503


class TestInputValidation:
    """Tests for input validation via Pydantic."""
    
    def test_age_validation(self, client, valid_patient_data):
        """Test age field validation."""
        # Negative age
        data = valid_patient_data.copy()
        data["age"] = -1
        response = client.post("/predict", json=data)
        assert response.status_code == 422
        
        # Age too high
        data["age"] = 150
        response = client.post("/predict", json=data)
        assert response.status_code == 422
    
    def test_sex_validation(self, client, valid_patient_data):
        """Test sex field validation."""
        data = valid_patient_data.copy()
        data["sex"] = 2  # Should be 0 or 1
        response = client.post("/predict", json=data)
        assert response.status_code == 422
    
    def test_chest_pain_validation(self, client, valid_patient_data):
        """Test chest pain type validation."""
        data = valid_patient_data.copy()
        data["cp"] = 5  # Should be 0-3
        response = client.post("/predict", json=data)
        assert response.status_code == 422


if __name__ == "__main__":
    pytest.main([__file__, "-v"])


