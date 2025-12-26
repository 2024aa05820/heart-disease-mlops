"""
Unit tests for model training and prediction.
"""

import pytest
import numpy as np
import pandas as pd
from pathlib import Path
import sys

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from sklearn.linear_model import LogisticRegression  # noqa: E402
from sklearn.ensemble import RandomForestClassifier  # noqa: E402

from src.models.train import get_model, evaluate_model  # noqa: E402
from src.models.predict import validate_features, FEATURE_SCHEMA  # noqa: E402


@pytest.fixture
def config():
    """Test configuration."""
    return {
        "model": {
            "logistic_regression": {
                "C": 1.0,
                "max_iter": 100,
                "random_state": 42
            },
            "random_forest": {
                "n_estimators": 10,
                "max_depth": 5,
                "random_state": 42
            },
            "cv_folds": 3
        }
    }


@pytest.fixture
def sample_training_data():
    """Generate sample training data."""
    np.random.seed(42)
    n_samples = 100
    n_features = 10
    
    X = np.random.randn(n_samples, n_features)
    y = (X[:, 0] + X[:, 1] > 0).astype(int)  # Simple linear boundary
    
    # Split into train/test
    split_idx = int(0.8 * n_samples)
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    return X_train, X_test, y_train, y_test


class TestModelCreation:
    """Tests for model creation."""
    
    def test_get_logistic_regression(self, config):
        """Test logistic regression model creation."""
        model = get_model("logistic_regression", config)
        assert isinstance(model, LogisticRegression)
        assert model.C == 1.0
    
    def test_get_random_forest(self, config):
        """Test random forest model creation."""
        model = get_model("random_forest", config)
        assert isinstance(model, RandomForestClassifier)
        assert model.n_estimators == 10
    
    def test_unknown_model_raises_error(self, config):
        """Test that unknown model name raises ValueError."""
        with pytest.raises(ValueError):
            get_model("unknown_model", config)


class TestModelTraining:
    """Tests for model training."""
    
    def test_logistic_regression_training(self, config, sample_training_data):
        """Test that logistic regression can be trained."""
        X_train, X_test, y_train, y_test = sample_training_data
        
        model = get_model("logistic_regression", config)
        model.fit(X_train, y_train)
        
        # Check predictions
        predictions = model.predict(X_test)
        assert len(predictions) == len(y_test)
        assert set(predictions).issubset({0, 1})
    
    def test_random_forest_training(self, config, sample_training_data):
        """Test that random forest can be trained."""
        X_train, X_test, y_train, y_test = sample_training_data
        
        model = get_model("random_forest", config)
        model.fit(X_train, y_train)
        
        # Check predictions
        predictions = model.predict(X_test)
        assert len(predictions) == len(y_test)
        assert set(predictions).issubset({0, 1})
    
    def test_model_predict_proba(self, config, sample_training_data):
        """Test that models return valid probabilities."""
        X_train, X_test, y_train, y_test = sample_training_data
        
        model = get_model("logistic_regression", config)
        model.fit(X_train, y_train)
        
        probas = model.predict_proba(X_test)
        
        # Check shape
        assert probas.shape == (len(y_test), 2)
        # Check probabilities sum to 1
        np.testing.assert_array_almost_equal(probas.sum(axis=1), np.ones(len(y_test)))
        # Check all values between 0 and 1
        assert (probas >= 0).all() and (probas <= 1).all()


class TestModelEvaluation:
    """Tests for model evaluation."""
    
    def test_evaluate_model_metrics(self, config, sample_training_data):
        """Test that evaluation returns expected metrics."""
        X_train, X_test, y_train, y_test = sample_training_data
        
        model = get_model("logistic_regression", config)
        model.fit(X_train, y_train)
        
        metrics = evaluate_model(
            model, X_train, X_test, y_train, y_test,
            cv_folds=config["model"]["cv_folds"]
        )
        
        expected_keys = [
            "cv_accuracy_mean", "cv_accuracy_std", "test_accuracy",
            "precision", "recall", "f1_score", "roc_auc"
        ]
        
        for key in expected_keys:
            assert key in metrics
            assert 0 <= metrics[key] <= 1
    
    def test_evaluate_model_cv_accuracy(self, config, sample_training_data):
        """Test cross-validation accuracy is reasonable."""
        X_train, X_test, y_train, y_test = sample_training_data
        
        model = get_model("logistic_regression", config)
        model.fit(X_train, y_train)
        
        metrics = evaluate_model(
            model, X_train, X_test, y_train, y_test,
            cv_folds=3
        )
        
        # CV accuracy should be better than random (0.5)
        assert metrics["cv_accuracy_mean"] > 0.5


class TestFeatureValidation:
    """Tests for feature validation."""
    
    def test_valid_features(self):
        """Test that valid features pass validation."""
        valid_features = {
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
        
        errors = validate_features(valid_features)
        assert len(errors) == 0
    
    def test_missing_feature(self):
        """Test that missing features are detected."""
        incomplete_features = {
            "age": 63,
            "sex": 1
            # Missing other features
        }
        
        errors = validate_features(incomplete_features)
        assert len(errors) > 0
        assert any("Missing" in e for e in errors)
    
    def test_out_of_range_feature(self):
        """Test that out-of-range values are detected."""
        invalid_features = {
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
        
        errors = validate_features(invalid_features)
        assert len(errors) > 0
        assert any("out of range" in e for e in errors)
    
    def test_feature_schema_complete(self):
        """Test that feature schema has all required fields."""
        expected_features = [
            "age", "sex", "cp", "trestbps", "chol", "fbs",
            "restecg", "thalach", "exang", "oldpeak", "slope", "ca", "thal"
        ]
        
        for feature in expected_features:
            assert feature in FEATURE_SCHEMA
            assert "type" in FEATURE_SCHEMA[feature]
            assert "min" in FEATURE_SCHEMA[feature]
            assert "max" in FEATURE_SCHEMA[feature]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])


