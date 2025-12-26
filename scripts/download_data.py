#!/usr/bin/env python3
"""
Download Heart Disease UCI Dataset

This script downloads the Heart Disease dataset from UCI Machine Learning Repository
and saves it to the data/raw directory.
"""

import os
import urllib.request
from pathlib import Path


def download_heart_disease_data():
    """Download the Heart Disease UCI dataset."""

    # Dataset URL (UCI ML Repository)
    # Using the processed Cleveland dataset
    url = "https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/processed.cleveland.data"

    # Alternative: Kaggle-style CSV with headers (more commonly used)
    # We'll create proper headers for the UCI data

    # Define paths
    project_root = Path(__file__).parent.parent
    raw_data_dir = project_root / "data" / "raw"
    raw_data_dir.mkdir(parents=True, exist_ok=True)

    output_file = raw_data_dir / "heart.csv"

    # Column names for the dataset
    columns = [
        "age",  # Age in years
        "sex",  # Sex (1 = male; 0 = female)
        "cp",  # Chest pain type (0-3)
        "trestbps",  # Resting blood pressure (mm Hg)
        "chol",  # Serum cholesterol (mg/dl)
        "fbs",  # Fasting blood sugar > 120 mg/dl (1 = true; 0 = false)
        "restecg",  # Resting ECG results (0-2)
        "thalach",  # Maximum heart rate achieved
        "exang",  # Exercise induced angina (1 = yes; 0 = no)
        "oldpeak",  # ST depression induced by exercise
        "slope",  # Slope of peak exercise ST segment (0-2)
        "ca",  # Number of major vessels colored by fluoroscopy (0-3)
        "thal",  # Thalassemia (1 = normal; 2 = fixed defect; 3 = reversible defect)
        "target",  # Heart disease (0 = no disease, 1-4 = disease present)
    ]

    print("Downloading Heart Disease dataset from UCI...")
    print(f"URL: {url}")

    try:
        # Download the data
        urllib.request.urlretrieve(url, raw_data_dir / "heart_raw.data")

        # Read and process the data
        with open(raw_data_dir / "heart_raw.data", "r") as f:
            lines = f.readlines()

        # Write with proper CSV headers
        with open(output_file, "w") as f:
            # Write header
            f.write(",".join(columns) + "\n")

            # Write data rows
            for line in lines:
                line = line.strip()
                if line:
                    # Replace '?' with empty string for missing values
                    line = line.replace("?", "")
                    f.write(line + "\n")

        # Clean up temporary file
        os.remove(raw_data_dir / "heart_raw.data")

        print(f"✓ Dataset saved to: {output_file}")
        print(f"✓ Columns: {len(columns)}")

        # Count rows
        with open(output_file, "r") as f:
            row_count = sum(1 for _ in f) - 1  # Subtract header
        print(f"✓ Rows: {row_count}")

        return str(output_file)

    except Exception as e:
        print(f"✗ Error downloading dataset: {e}")
        print("\nAlternative: Download manually from:")
        print("  https://www.kaggle.com/datasets/redwankarimsony/heart-disease-data")
        print("  or")
        print("  https://archive.ics.uci.edu/ml/datasets/heart+disease")
        raise


def verify_data(filepath: str):
    """Verify the downloaded data."""
    import pandas as pd

    print("\n--- Data Verification ---")
    df = pd.read_csv(filepath)
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print("\nFirst 5 rows:")
    print(df.head())
    print("\nData types:")
    print(df.dtypes)
    print("\nMissing values:")
    print(df.isnull().sum())


if __name__ == "__main__":
    filepath = download_heart_disease_data()
    verify_data(filepath)
