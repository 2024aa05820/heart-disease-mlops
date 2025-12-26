"""
Prediction module for Heart Disease classification.

Provides functions to load the model and make predictions.
"""

import joblib
import pandas as pd
from pathlib import Path
from typing import Dict, Union, List


class HeartDiseasePredictor:
    """Predictor class for heart disease classification."""

    def __init__(
        self,
        model_path: str = "models/best_model.joblib",
        pipeline_path: str = "models/preprocessing_pipeline.joblib",
    ):
        """
        Initialize the predictor.

        Args:
            model_path: Path to the saved model
            pipeline_path: Path to the preprocessing pipeline
        """
        self.model_path = Path(model_path)
        self.pipeline_path = Path(pipeline_path)
        self.model = None
        self.preprocessor = None
        self._load_artifacts()

    def _load_artifacts(self):
        """Load model and preprocessor from disk."""
        if not self.model_path.exists():
            raise FileNotFoundError(f"Model not found: {self.model_path}")
        if not self.pipeline_path.exists():
            raise FileNotFoundError(f"Preprocessor not found: {self.pipeline_path}")

        self.model = joblib.load(self.model_path)
        self.preprocessor = joblib.load(self.pipeline_path)

    def predict(self, features: Dict[str, Union[int, float]]) -> Dict[str, any]:
        """
        Make a prediction for a single patient.

        Args:
            features: Dictionary of patient features
                Required keys: age, sex, cp, trestbps, chol, fbs,
                              restecg, thalach, exang, oldpeak, slope, ca, thal

        Returns:
            Dictionary with prediction and probability
        """
        # Convert to DataFrame
        df = pd.DataFrame([features])

        # Preprocess
        X = self.preprocessor.transform(df)

        # Predict
        prediction = self.model.predict(X)[0]
        probability = self.model.predict_proba(X)[0]

        return {
            "prediction": int(prediction),
            "prediction_label": (
                "Heart Disease" if prediction == 1 else "No Heart Disease"
            ),
            "probability_no_disease": float(probability[0]),
            "probability_disease": float(probability[1]),
            "confidence": float(max(probability)),
        }

    def predict_batch(
        self, features_list: List[Dict[str, Union[int, float]]]
    ) -> List[Dict[str, any]]:
        """
        Make predictions for multiple patients.

        Args:
            features_list: List of feature dictionaries

        Returns:
            List of prediction dictionaries
        """
        return [self.predict(features) for features in features_list]


# Feature schema for validation
FEATURE_SCHEMA = {
    "age": {"type": "int", "min": 0, "max": 120, "description": "Age in years"},
    "sex": {
        "type": "int",
        "min": 0,
        "max": 1,
        "description": "Sex (1 = male, 0 = female)",
    },
    "cp": {"type": "int", "min": 0, "max": 3, "description": "Chest pain type (0-3)"},
    "trestbps": {
        "type": "int",
        "min": 50,
        "max": 250,
        "description": "Resting blood pressure (mm Hg)",
    },
    "chol": {
        "type": "int",
        "min": 100,
        "max": 600,
        "description": "Serum cholesterol (mg/dl)",
    },
    "fbs": {
        "type": "int",
        "min": 0,
        "max": 1,
        "description": "Fasting blood sugar > 120 mg/dl",
    },
    "restecg": {
        "type": "int",
        "min": 0,
        "max": 2,
        "description": "Resting ECG results (0-2)",
    },
    "thalach": {
        "type": "int",
        "min": 50,
        "max": 250,
        "description": "Maximum heart rate achieved",
    },
    "exang": {
        "type": "int",
        "min": 0,
        "max": 1,
        "description": "Exercise induced angina",
    },
    "oldpeak": {
        "type": "float",
        "min": 0,
        "max": 10,
        "description": "ST depression induced by exercise",
    },
    "slope": {
        "type": "int",
        "min": 0,
        "max": 2,
        "description": "Slope of peak exercise ST segment",
    },
    "ca": {
        "type": "int",
        "min": 0,
        "max": 4,
        "description": "Number of major vessels (0-4)",
    },
    "thal": {"type": "int", "min": 0, "max": 3, "description": "Thalassemia (0-3)"},
}


def validate_features(features: Dict[str, Union[int, float]]) -> List[str]:
    """
    Validate input features against schema.

    Args:
        features: Dictionary of features

    Returns:
        List of validation errors (empty if valid)
    """
    errors = []

    # Check for missing features
    for key in FEATURE_SCHEMA:
        if key not in features:
            errors.append(f"Missing required feature: {key}")

    # Check value ranges
    for key, value in features.items():
        if key in FEATURE_SCHEMA:
            schema = FEATURE_SCHEMA[key]
            if value < schema["min"] or value > schema["max"]:
                errors.append(
                    f"{key}: value {value} out of range [{schema['min']}, {schema['max']}]"
                )

    return errors


if __name__ == "__main__":
    # Test prediction
    predictor = HeartDiseasePredictor()

    # Sample patient data
    sample_patient = {
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

    # Validate
    errors = validate_features(sample_patient)
    if errors:
        print("Validation errors:", errors)
    else:
        # Predict
        result = predictor.predict(sample_patient)
        print("Prediction:", result)
