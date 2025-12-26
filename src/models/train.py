"""
Model training module for Heart Disease prediction.

Trains multiple models, tracks experiments with MLflow,
and saves the best model.
"""

import sys
from pathlib import Path
from typing import Dict, Any, Tuple
import warnings

import numpy as np
import joblib
import yaml
import mlflow
import mlflow.sklearn
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report,
    roc_curve,
)
import matplotlib.pyplot as plt

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from src.data.pipeline import (  # noqa: E402
    load_config,
    load_data,
    prepare_data,
    split_data,
    save_preprocessor,
)

warnings.filterwarnings("ignore")


def get_model(model_name: str, config: dict):
    """
    Get a model instance based on name.

    Args:
        model_name: Name of the model
        config: Configuration dictionary

    Returns:
        Sklearn model instance
    """
    if model_name == "logistic_regression":
        params = config["model"]["logistic_regression"]
        return LogisticRegression(**params)
    elif model_name == "random_forest":
        params = config["model"]["random_forest"]
        return RandomForestClassifier(**params)
    else:
        raise ValueError(f"Unknown model: {model_name}")


def evaluate_model(
    model,
    X_train: np.ndarray,
    X_test: np.ndarray,
    y_train: np.ndarray,
    y_test: np.ndarray,
    cv_folds: int = 5,
) -> Dict[str, Any]:
    """
    Evaluate model performance with multiple metrics.

    Args:
        model: Trained sklearn model
        X_train, X_test: Feature matrices
        y_train, y_test: Target vectors
        cv_folds: Number of cross-validation folds

    Returns:
        Dictionary of evaluation metrics
    """
    # Cross-validation scores
    cv_scores = cross_val_score(
        model, X_train, y_train, cv=cv_folds, scoring="accuracy"
    )

    # Predictions
    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)[:, 1]

    # Calculate metrics
    metrics = {
        "cv_accuracy_mean": cv_scores.mean(),
        "cv_accuracy_std": cv_scores.std(),
        "test_accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred),
        "recall": recall_score(y_test, y_pred),
        "f1_score": f1_score(y_test, y_pred),
        "roc_auc": roc_auc_score(y_test, y_prob),
    }

    return metrics


def plot_roc_curve(
    y_test: np.ndarray, y_prob: np.ndarray, model_name: str
) -> plt.Figure:
    """Plot ROC curve."""
    fpr, tpr, _ = roc_curve(y_test, y_prob)
    auc = roc_auc_score(y_test, y_prob)

    fig, ax = plt.subplots(figsize=(8, 6))
    ax.plot(fpr, tpr, label=f"{model_name} (AUC = {auc:.3f})")
    ax.plot([0, 1], [0, 1], "k--", label="Random")
    ax.set_xlabel("False Positive Rate")
    ax.set_ylabel("True Positive Rate")
    ax.set_title(f"ROC Curve - {model_name}")
    ax.legend()
    ax.grid(True, alpha=0.3)

    return fig


def plot_confusion_matrix(
    y_test: np.ndarray, y_pred: np.ndarray, model_name: str
) -> plt.Figure:
    """Plot confusion matrix."""
    cm = confusion_matrix(y_test, y_pred)

    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.imshow(cm, interpolation="nearest", cmap=plt.cm.Blues)
    ax.figure.colorbar(im, ax=ax)

    ax.set(
        xticks=[0, 1],
        yticks=[0, 1],
        xticklabels=["No Disease", "Disease"],
        yticklabels=["No Disease", "Disease"],
        xlabel="Predicted",
        ylabel="Actual",
        title=f"Confusion Matrix - {model_name}",
    )

    # Add text annotations
    thresh = cm.max() / 2
    for i in range(2):
        for j in range(2):
            ax.text(
                j,
                i,
                format(cm[i, j], "d"),
                ha="center",
                va="center",
                color="white" if cm[i, j] > thresh else "black",
            )

    fig.tight_layout()
    return fig


def plot_feature_importance(model, feature_names: list, model_name: str) -> plt.Figure:
    """Plot feature importance (for tree-based models)."""
    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
    elif hasattr(model, "coef_"):
        importances = np.abs(model.coef_[0])
    else:
        return None

    # Sort by importance
    indices = np.argsort(importances)[::-1][:15]  # Top 15

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.barh(range(len(indices)), importances[indices])
    ax.set_yticks(range(len(indices)))

    # Use feature indices if names not available
    if feature_names and len(feature_names) > max(indices):
        labels = [feature_names[i] for i in indices]
    else:
        labels = [f"Feature {i}" for i in indices]

    ax.set_yticklabels(labels)
    ax.set_xlabel("Importance")
    ax.set_title(f"Feature Importance - {model_name}")
    ax.invert_yaxis()

    fig.tight_layout()
    return fig


def train_and_log_model(
    model_name: str,
    config: dict,
    X_train: np.ndarray,
    X_test: np.ndarray,
    y_train: np.ndarray,
    y_test: np.ndarray,
) -> Tuple[Any, Dict[str, float]]:
    """
    Train a model and log to MLflow.

    Args:
        model_name: Name of the model to train
        config: Configuration dictionary
        X_train, X_test: Feature matrices
        y_train, y_test: Target vectors

    Returns:
        Tuple of (trained model, metrics dictionary)
    """
    with mlflow.start_run(run_name=model_name):
        # Get model
        model = get_model(model_name, config)

        # Log parameters
        if model_name == "logistic_regression":
            mlflow.log_params(config["model"]["logistic_regression"])
        elif model_name == "random_forest":
            mlflow.log_params(config["model"]["random_forest"])

        # Train model
        model.fit(X_train, y_train)

        # Evaluate
        metrics = evaluate_model(
            model,
            X_train,
            X_test,
            y_train,
            y_test,
            cv_folds=config["model"]["cv_folds"],
        )

        # Log metrics
        mlflow.log_metrics(metrics)

        # Generate and log plots
        y_pred = model.predict(X_test)
        y_prob = model.predict_proba(X_test)[:, 1]

        # ROC curve
        roc_fig = plot_roc_curve(y_test, y_prob, model_name)
        mlflow.log_figure(roc_fig, f"roc_curve_{model_name}.png")
        plt.close(roc_fig)

        # Confusion matrix
        cm_fig = plot_confusion_matrix(y_test, y_pred, model_name)
        mlflow.log_figure(cm_fig, f"confusion_matrix_{model_name}.png")
        plt.close(cm_fig)

        # Feature importance
        fi_fig = plot_feature_importance(model, [], model_name)
        if fi_fig:
            mlflow.log_figure(fi_fig, f"feature_importance_{model_name}.png")
            plt.close(fi_fig)

        # Log model
        mlflow.sklearn.log_model(model, model_name)

        # Print classification report
        print(f"\n{'='*50}")
        print(f"Model: {model_name}")
        print(f"{'='*50}")
        print(
            classification_report(
                y_test, y_pred, target_names=["No Disease", "Disease"]
            )
        )
        print(f"ROC-AUC: {metrics['roc_auc']:.4f}")
        print(
            f"CV Accuracy: {metrics['cv_accuracy_mean']:.4f} (+/- {metrics['cv_accuracy_std']:.4f})"
        )

    return model, metrics


def save_model(model, filepath: str):
    """Save model to disk."""
    Path(filepath).parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, filepath)
    print(f"Model saved to: {filepath}")


def train_all_models(config_path: str = "src/config/config.yaml"):
    """
    Main training function. Trains all models and saves the best one.

    Args:
        config_path: Path to configuration file
    """
    # Load config
    config = load_config(config_path)

    # Setup MLflow
    mlflow.set_tracking_uri(config["mlflow"]["tracking_uri"])
    mlflow.set_experiment(config["mlflow"]["experiment_name"])

    print("=" * 60)
    print("Heart Disease Classification - Model Training")
    print("=" * 60)

    # Load and prepare data
    print("\n1. Loading data...")
    df = load_data(config["data"]["raw_path"])
    print(f"   Loaded {len(df)} samples")

    print("\n2. Preprocessing data...")
    X, y, preprocessor = prepare_data(df, config)
    print(f"   Features shape: {X.shape}")

    print("\n3. Splitting data...")
    X_train, X_test, y_train, y_test = split_data(
        X,
        y,
        test_size=config["data"]["test_size"],
        random_state=config["data"]["random_state"],
    )
    print(f"   Train: {X_train.shape[0]}, Test: {X_test.shape[0]}")

    # Train models
    print("\n4. Training models...")
    results = {}

    for model_name in config["model"]["models_to_train"]:
        model, metrics = train_and_log_model(
            model_name, config, X_train, X_test, y_train, y_test
        )
        results[model_name] = {"model": model, "metrics": metrics}

    # Select best model based on ROC-AUC
    print("\n5. Selecting best model...")
    best_model_name = max(results, key=lambda x: results[x]["metrics"]["roc_auc"])
    best_model = results[best_model_name]["model"]
    best_metrics = results[best_model_name]["metrics"]

    print(f"   Best model: {best_model_name}")
    print(f"   ROC-AUC: {best_metrics['roc_auc']:.4f}")

    # Save best model and preprocessor
    print("\n6. Saving artifacts...")
    models_dir = Path("models")
    models_dir.mkdir(exist_ok=True)

    save_model(best_model, str(models_dir / "best_model.joblib"))
    save_preprocessor(preprocessor, str(models_dir / "preprocessing_pipeline.joblib"))

    # Save model info
    model_info = {
        "model_name": best_model_name,
        "metrics": best_metrics,
        "config": config,
    }
    with open(models_dir / "model_info.yaml", "w") as f:
        yaml.dump(model_info, f)

    print("\n" + "=" * 60)
    print("Training complete!")
    print(f"Best model ({best_model_name}) saved to: models/best_model.joblib")
    print(f"MLflow runs logged to: {config['mlflow']['tracking_uri']}")
    print("=" * 60)

    return best_model, preprocessor


if __name__ == "__main__":
    train_all_models()
