"""
Data preprocessing pipeline for Heart Disease prediction.

This module provides functions for:
- Loading and cleaning data
- Feature engineering
- Building sklearn preprocessing pipelines
"""

import pandas as pd
import numpy as np
from pathlib import Path
from typing import Tuple, List, Optional
import joblib
import yaml

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer


def load_config(config_path: str = "src/config/config.yaml") -> dict:
    """Load configuration from YAML file."""
    with open(config_path, "r") as f:
        return yaml.safe_load(f)


def load_data(filepath: str) -> pd.DataFrame:
    """
    Load the heart disease dataset.

    Args:
        filepath: Path to the CSV file

    Returns:
        DataFrame with the loaded data
    """
    df = pd.read_csv(filepath)
    return df


def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean the dataset by handling missing values and invalid entries.

    Args:
        df: Raw DataFrame

    Returns:
        Cleaned DataFrame
    """
    df = df.copy()

    # Convert target to binary (0 = no disease, 1 = disease)
    # Original values: 0 = no disease, 1-4 = varying degrees of disease
    if "target" in df.columns:
        df["target"] = (df["target"] > 0).astype(int)

    # Handle missing values (marked as '?' in original data, converted to NaN)
    # For numerical columns: impute with median
    # For categorical columns: impute with mode

    numerical_cols = ["age", "trestbps", "chol", "thalach", "oldpeak"]
    categorical_cols = ["sex", "cp", "fbs", "restecg", "exang", "slope", "ca", "thal"]

    for col in numerical_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
            df[col] = df[col].fillna(df[col].median())

    for col in categorical_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
            df[col] = df[col].fillna(
                df[col].mode()[0] if not df[col].mode().empty else 0
            )

    # Drop rows with any remaining NaN
    df = df.dropna()

    return df


def get_feature_target_split(
    df: pd.DataFrame, target_col: str = "target"
) -> Tuple[pd.DataFrame, pd.Series]:
    """
    Split DataFrame into features and target.

    Args:
        df: DataFrame with features and target
        target_col: Name of target column

    Returns:
        Tuple of (features DataFrame, target Series)
    """
    X = df.drop(columns=[target_col])
    y = df[target_col]
    return X, y


def create_preprocessing_pipeline(
    numerical_features: List[str], categorical_features: List[str]
) -> ColumnTransformer:
    """
    Create a sklearn preprocessing pipeline.

    Args:
        numerical_features: List of numerical column names
        categorical_features: List of categorical column names

    Returns:
        ColumnTransformer for preprocessing
    """
    # Numerical pipeline: impute missing + scale
    numerical_pipeline = Pipeline(
        [("imputer", SimpleImputer(strategy="median")), ("scaler", StandardScaler())]
    )

    # Categorical pipeline: impute missing + one-hot encode
    categorical_pipeline = Pipeline(
        [
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("encoder", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
        ]
    )

    # Combine into ColumnTransformer
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", numerical_pipeline, numerical_features),
            ("cat", categorical_pipeline, categorical_features),
        ],
        remainder="passthrough",
    )

    return preprocessor


def prepare_data(
    df: pd.DataFrame,
    config: dict,
    fit_preprocessor: bool = True,
    preprocessor: Optional[ColumnTransformer] = None,
) -> Tuple[np.ndarray, np.ndarray, ColumnTransformer]:
    """
    Prepare data for model training/inference.

    Args:
        df: Input DataFrame
        config: Configuration dictionary
        fit_preprocessor: Whether to fit the preprocessor
        preprocessor: Existing preprocessor (for inference)

    Returns:
        Tuple of (X_processed, y, preprocessor)
    """
    # Clean data
    df_clean = clean_data(df)

    # Split features and target
    X, y = get_feature_target_split(df_clean, config["features"]["target"])

    # Get feature lists
    numerical_features = [f for f in config["features"]["numerical"] if f in X.columns]
    categorical_features = [
        f for f in config["features"]["categorical"] if f in X.columns
    ]

    # Create or use existing preprocessor
    if preprocessor is None:
        preprocessor = create_preprocessing_pipeline(
            numerical_features, categorical_features
        )

    # Fit and transform or just transform
    if fit_preprocessor:
        X_processed = preprocessor.fit_transform(X)
    else:
        X_processed = preprocessor.transform(X)

    return X_processed, y.values, preprocessor


def split_data(
    X: np.ndarray, y: np.ndarray, test_size: float = 0.2, random_state: int = 42
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Split data into train and test sets.

    Args:
        X: Feature matrix
        y: Target vector
        test_size: Proportion of data for testing
        random_state: Random seed for reproducibility

    Returns:
        Tuple of (X_train, X_test, y_train, y_test)
    """
    return train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )


def save_preprocessor(preprocessor: ColumnTransformer, filepath: str):
    """Save preprocessing pipeline to disk."""
    Path(filepath).parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(preprocessor, filepath)
    print(f"Preprocessor saved to: {filepath}")


def load_preprocessor(filepath: str) -> ColumnTransformer:
    """Load preprocessing pipeline from disk."""
    return joblib.load(filepath)


if __name__ == "__main__":
    # Test the pipeline
    config = load_config()
    df = load_data(config["data"]["raw_path"])
    print(f"Loaded data shape: {df.shape}")

    X, y, preprocessor = prepare_data(df, config)
    print(f"Processed features shape: {X.shape}")
    print(f"Target shape: {y.shape}")

    X_train, X_test, y_train, y_test = split_data(
        X,
        y,
        test_size=config["data"]["test_size"],
        random_state=config["data"]["random_state"],
    )
    print(f"Train: {X_train.shape}, Test: {X_test.shape}")
