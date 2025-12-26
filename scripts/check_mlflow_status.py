#!/usr/bin/env python3
"""
MLflow Status Checker

This script checks if MLflow experiments exist and provides guidance.
Run this to diagnose why MLflow UI is empty.
"""

import sys
from pathlib import Path

# Colors for terminal output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"


def print_status(message, status="info"):
    """Print colored status message."""
    if status == "success":
        print(f"{GREEN}✓ {message}{RESET}")
    elif status == "error":
        print(f"{RED}✗ {message}{RESET}")
    elif status == "warning":
        print(f"{YELLOW}⚠ {message}{RESET}")
    else:
        print(f"{BLUE}ℹ {message}{RESET}")


def check_project_structure():
    """Check if we're in the right directory."""
    print("\n" + "=" * 60)
    print("CHECKING PROJECT STRUCTURE")
    print("=" * 60)

    required_dirs = ["src", "scripts", "data", "models"]
    required_files = ["requirements.txt", "README.md"]

    all_good = True

    for dir_name in required_dirs:
        if Path(dir_name).exists():
            print_status(f"Directory '{dir_name}/' exists", "success")
        else:
            print_status(f"Directory '{dir_name}/' NOT FOUND", "error")
            all_good = False

    for file_name in required_files:
        if Path(file_name).exists():
            print_status(f"File '{file_name}' exists", "success")
        else:
            print_status(f"File '{file_name}' NOT FOUND", "error")
            all_good = False

    return all_good


def check_dataset():
    """Check if dataset has been downloaded."""
    print("\n" + "=" * 60)
    print("CHECKING DATASET")
    print("=" * 60)

    data_file = Path("data/raw/heart.csv")

    if data_file.exists():
        size = data_file.stat().st_size
        print_status(f"Dataset found: {data_file} ({size} bytes)", "success")

        # Check if file has content
        if size > 1000:
            print_status("Dataset appears to have data", "success")
            return True
        else:
            print_status("Dataset file is too small - may be empty", "warning")
            return False
    else:
        print_status("Dataset NOT FOUND", "error")
        print_status("Run: python scripts/download_data.py", "info")
        return False


def check_mlflow_runs():
    """Check if MLflow runs exist."""
    print("\n" + "=" * 60)
    print("CHECKING MLFLOW EXPERIMENTS")
    print("=" * 60)

    mlruns_dir = Path("mlruns")

    if not mlruns_dir.exists():
        print_status("mlruns/ directory NOT FOUND", "error")
        print_status("No experiments have been logged yet", "warning")
        print_status("Run: python scripts/train.py", "info")
        return False

    print_status("mlruns/ directory exists", "success")

    # Check for experiment directories
    experiment_dirs = [
        d for d in mlruns_dir.iterdir() if d.is_dir() and d.name.isdigit()
    ]

    if not experiment_dirs:
        print_status("No experiment directories found", "error")
        print_status("Run: python scripts/train.py", "info")
        return False

    print_status(f"Found {len(experiment_dirs)} experiment(s)", "success")

    # Check for runs in experiments
    total_runs = 0
    for exp_dir in experiment_dirs:
        run_dirs = [
            d for d in exp_dir.iterdir() if d.is_dir() and d.name != "meta.yaml"
        ]
        total_runs += len(run_dirs)

        if len(run_dirs) > 0:
            print_status(
                f"Experiment {exp_dir.name}: {len(run_dirs)} run(s)", "success"
            )

    if total_runs == 0:
        print_status("No runs found in experiments", "error")
        print_status("Run: python scripts/train.py", "info")
        return False

    print_status(f"Total runs found: {total_runs}", "success")
    return True


def check_models():
    """Check if trained models exist."""
    print("\n" + "=" * 60)
    print("CHECKING SAVED MODELS")
    print("=" * 60)

    models_dir = Path("models")

    if not models_dir.exists():
        print_status("models/ directory NOT FOUND", "error")
        return False

    # Look for model files
    model_files = list(models_dir.glob("*.pkl")) + list(models_dir.glob("*.joblib"))

    if model_files:
        print_status(f"Found {len(model_files)} model file(s)", "success")
        for model_file in model_files:
            print_status(f"  - {model_file.name}", "info")
        return True
    else:
        print_status("No model files found", "warning")
        print_status("Run: python scripts/train.py", "info")
        return False


def provide_recommendations():
    """Provide recommendations based on checks."""
    print("\n" + "=" * 60)
    print("RECOMMENDATIONS")
    print("=" * 60)

    data_ok = check_dataset()
    mlflow_ok = check_mlflow_runs()

    if not data_ok:
        print(f"\n{YELLOW}STEP 1: Download the dataset{RESET}")
        print("  Command: python scripts/download_data.py")
        print("  This will download the Heart Disease dataset from UCI")

    if not mlflow_ok:
        print(f"\n{YELLOW}STEP 2: Train the models{RESET}")
        print("  Command: python scripts/train.py")
        print("  This will:")
        print("    - Train Logistic Regression and Random Forest models")
        print("    - Log experiments to MLflow")
        print("    - Save models to models/ directory")
        print("  Expected time: 2-5 minutes")

    if mlflow_ok:
        print(f"\n{GREEN}STEP 3: Start MLflow UI{RESET}")
        print("  Command: mlflow ui --host 0.0.0.0 --port 5000")
        print("  Access from browser: http://<SERVER_IP>:5000")
        print(f"\n{GREEN}✓ Your MLflow experiments are ready!{RESET}")


def main():
    """Main function."""
    print(f"\n{BLUE}{'='*60}")
    print("MLflow Status Checker")
    print(f"{'='*60}{RESET}\n")

    # Check project structure
    if not check_project_structure():
        print_status("\nERROR: Not in project root directory", "error")
        print_status("Navigate to: heart-disease-mlops/", "info")
        sys.exit(1)

    # Check dataset
    check_dataset()

    # Check MLflow runs
    check_mlflow_runs()

    # Check models
    check_models()

    # Provide recommendations
    provide_recommendations()

    print(f"\n{BLUE}{'='*60}{RESET}\n")


if __name__ == "__main__":
    main()
