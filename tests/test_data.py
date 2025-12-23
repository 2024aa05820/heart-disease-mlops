"""
Unit tests for data processing pipeline.
"""

import pytest
import pandas as pd
import numpy as np
from pathlib import Path
import sys

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.data.pipeline import (
    load_config,
    clean_data,
    get_feature_target_split,
    create_preprocessing_pipeline,
    split_data
)


@pytest.fixture
def sample_data():
    """Create sample data for testing."""
    return pd.DataFrame({
        "age": [63, 67, 37, 41, 56],
        "sex": [1, 1, 1, 0, 1],
        "cp": [3, 3, 2, 1, 1],
        "trestbps": [145, 160, 130, 130, 120],
        "chol": [233, 286, 250, 204, 236],
        "fbs": [1, 0, 0, 0, 0],
        "restecg": [0, 0, 1, 0, 1],
        "thalach": [150, 108, 187, 172, 178],
        "exang": [0, 1, 0, 0, 0],
        "oldpeak": [2.3, 1.5, 3.5, 1.4, 0.8],
        "slope": [0, 1, 0, 2, 2],
        "ca": [0, 3, 0, 0, 0],
        "thal": [1, 2, 2, 2, 2],
        "target": [1, 2, 1, 0, 0]  # Original values 0-4
    })


@pytest.fixture
def config():
    """Load test configuration."""
    return {
        "features": {
            "numerical": ["age", "trestbps", "chol", "thalach", "oldpeak"],
            "categorical": ["sex", "cp", "fbs", "restecg", "exang", "slope", "ca", "thal"],
            "target": "target"
        },
        "data": {
            "test_size": 0.2,
            "random_state": 42
        }
    }


class TestDataLoading:
    """Tests for data loading functionality."""
    
    def test_config_loading(self):
        """Test that config can be loaded."""
        config_path = project_root / "src" / "config" / "config.yaml"
        if config_path.exists():
            config = load_config(str(config_path))
            assert "data" in config
            assert "features" in config
            assert "model" in config


class TestDataCleaning:
    """Tests for data cleaning functionality."""
    
    def test_clean_data_binary_target(self, sample_data):
        """Test that target is converted to binary."""
        cleaned = clean_data(sample_data)
        assert cleaned["target"].isin([0, 1]).all()
    
    def test_clean_data_no_nulls(self, sample_data):
        """Test that cleaned data has no null values."""
        # Add some nulls
        sample_data.loc[0, "age"] = np.nan
        cleaned = clean_data(sample_data)
        assert cleaned.isnull().sum().sum() == 0
    
    def test_clean_data_preserves_rows(self, sample_data):
        """Test that cleaning preserves most data."""
        cleaned = clean_data(sample_data)
        # Should keep most rows (may drop some with NaN)
        assert len(cleaned) >= len(sample_data) - 1


class TestFeatureEngineering:
    """Tests for feature engineering."""
    
    def test_feature_target_split(self, sample_data, config):
        """Test feature-target splitting."""
        cleaned = clean_data(sample_data)
        X, y = get_feature_target_split(cleaned, config["features"]["target"])
        
        assert "target" not in X.columns
        assert len(y) == len(X)
    
    def test_preprocessing_pipeline_creation(self, config):
        """Test preprocessing pipeline creation."""
        pipeline = create_preprocessing_pipeline(
            config["features"]["numerical"],
            config["features"]["categorical"]
        )
        assert pipeline is not None
    
    def test_preprocessing_pipeline_transform(self, sample_data, config):
        """Test that preprocessing pipeline transforms data correctly."""
        cleaned = clean_data(sample_data)
        X, y = get_feature_target_split(cleaned, config["features"]["target"])
        
        pipeline = create_preprocessing_pipeline(
            config["features"]["numerical"],
            config["features"]["categorical"]
        )
        
        X_transformed = pipeline.fit_transform(X)
        
        # Check output is numpy array
        assert isinstance(X_transformed, np.ndarray)
        # Check no NaN values
        assert not np.isnan(X_transformed).any()
        # Check rows preserved
        assert X_transformed.shape[0] == len(X)


class TestDataSplitting:
    """Tests for data splitting."""
    
    def test_split_data_shapes(self, sample_data, config):
        """Test that split data has correct shapes."""
        cleaned = clean_data(sample_data)
        X, y = get_feature_target_split(cleaned, config["features"]["target"])
        
        pipeline = create_preprocessing_pipeline(
            config["features"]["numerical"],
            config["features"]["categorical"]
        )
        X_processed = pipeline.fit_transform(X)
        
        X_train, X_test, y_train, y_test = split_data(
            X_processed, y.values,
            test_size=config["data"]["test_size"],
            random_state=config["data"]["random_state"]
        )
        
        total_samples = len(X_processed)
        assert len(X_train) + len(X_test) == total_samples
        assert len(y_train) + len(y_test) == total_samples
    
    def test_split_data_reproducibility(self, sample_data, config):
        """Test that splitting is reproducible with same seed."""
        cleaned = clean_data(sample_data)
        X, y = get_feature_target_split(cleaned, config["features"]["target"])
        
        pipeline = create_preprocessing_pipeline(
            config["features"]["numerical"],
            config["features"]["categorical"]
        )
        X_processed = pipeline.fit_transform(X)
        
        # First split
        X_train1, _, y_train1, _ = split_data(
            X_processed, y.values,
            test_size=0.2,
            random_state=42
        )
        
        # Second split with same seed
        X_train2, _, y_train2, _ = split_data(
            X_processed, y.values,
            test_size=0.2,
            random_state=42
        )
        
        np.testing.assert_array_equal(X_train1, X_train2)
        np.testing.assert_array_equal(y_train1, y_train2)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])


