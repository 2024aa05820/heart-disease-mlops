#!/usr/bin/env python3
"""
Script to manually promote a model to Production stage in MLflow Model Registry.

This is a workaround for the RepresentationError that occurs when trying to
transition model stages programmatically in some MLflow versions.

Usage:
    python scripts/promote-model.py <model_name> [version]

Examples:
    # Promote latest version of logistic_regression to Production
    python scripts/promote-model.py heart-disease-logistic_regression

    # Promote specific version to Production
    python scripts/promote-model.py heart-disease-logistic_regression 2
"""

import sys
from pathlib import Path

import mlflow
from mlflow.tracking import MlflowClient

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


def promote_model(model_name: str, version: str = None):
    """
    Promote a model version to Production stage.

    Args:
        model_name: Name of the registered model
        version: Version number (optional, defaults to latest)
    """
    # Set tracking URI
    mlflow.set_tracking_uri("mlruns")

    client = MlflowClient()

    print(f"🔍 Looking for model: {model_name}")

    try:
        # Get model versions
        all_versions = client.search_model_versions(f"name='{model_name}'")

        if not all_versions:
            print(f"❌ No versions found for model '{model_name}'")
            print("\nAvailable models:")
            for rm in client.search_registered_models():
                print(f"  - {rm.name}")
            return False

        # Sort by version number
        all_versions.sort(key=lambda x: int(x.version), reverse=True)

        # Select version
        if version:
            target_version = version
            version_obj = next((v for v in all_versions if v.version == version), None)
            if not version_obj:
                print(f"❌ Version {version} not found for model '{model_name}'")
                print("\nAvailable versions:")
                for v in all_versions:
                    print(f"  - Version {v.version} (Stage: {v.current_stage})")
                return False
        else:
            version_obj = all_versions[0]
            target_version = version_obj.version

        print(f"✅ Found version {target_version}")
        print(f"   Current stage: {version_obj.current_stage}")

        # Check if already in Production
        if version_obj.current_stage == "Production":
            print(f"ℹ️  Version {target_version} is already in Production stage")
            return True

        # Archive existing Production versions
        print("\n📦 Checking for existing Production versions...")
        production_versions = client.get_latest_versions(model_name, stages=["Production"])

        for pv in production_versions:
            print(f"   Archiving version {pv.version}...")
            try:
                client.transition_model_version_stage(
                    name=model_name,
                    version=pv.version,
                    stage="Archived",
                    archive_existing_versions=False
                )
                print(f"   ✅ Version {pv.version} archived")
            except Exception as e:
                print(f"   ⚠️  Could not archive version {pv.version}: {e}")

        # Promote to Production - Method 1: Standard API
        print(f"\n🚀 Promoting version {target_version} to Production...")

        try:
            client.transition_model_version_stage(
                name=model_name,
                version=target_version,
                stage="Production",
                archive_existing_versions=True
            )
            print(f"✅ Successfully promoted {model_name} v{target_version} to Production!")
            return True

        except Exception as e:
            error_name = type(e).__name__
            print(f"⚠️  Method 1 failed: {error_name}")

            # Method 2: Try with archive_existing_versions=False
            if "Representation" in error_name or "cannot represent" in str(e):
                print("🔄 Trying alternative method...")
                try:
                    client.transition_model_version_stage(
                        name=model_name,
                        version=target_version,
                        stage="Production",
                        archive_existing_versions=False
                    )
                    print(f"✅ Successfully promoted {model_name} v{target_version} to Production!")
                    return True
                except Exception as e2:
                    print(f"⚠️  Method 2 also failed: {type(e2).__name__}")

            # All methods failed
            print("\n❌ All promotion methods failed")
            print(f"   Original error: {str(e)[:200]}")
            print("\n💡 Manual promotion required:")
            print("   1. Open MLflow UI: http://localhost:5000")
            print("   2. Go to Models tab")
            print(f"   3. Click '{model_name}'")
            print(f"   4. Click 'Version {target_version}'")
            print("   5. Change Stage dropdown to 'Production'")
            print("   6. Click 'Save'")
            return False

    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
        return False


def cleanup_old_versions(model_name: str = None, keep_last: int = 3):
    """
    Delete old model versions, keeping only the most recent ones.
    WARNING: This is destructive and cannot be undone!

    Args:
        model_name: Specific model to clean (None = all models)
        keep_last: Number of recent versions to keep per model
    """
    mlflow.set_tracking_uri("mlruns")
    client = MlflowClient()

    print(f"🧹 Cleaning up old model versions (keeping last {keep_last})...")
    print("⚠️  WARNING: This will permanently delete old versions!")

    try:
        # Get models to clean
        if model_name:
            models = [rm for rm in client.search_registered_models() if rm.name == model_name]
            if not models:
                print(f"❌ Model '{model_name}' not found")
                return False
        else:
            models = client.search_registered_models()

        for model in models:
            print(f"\n📦 Processing {model.name}...")

            # Get all versions
            versions = client.search_model_versions(f"name='{model.name}'")
            versions.sort(key=lambda x: int(x.version), reverse=True)

            # Keep Production and recent versions
            versions_to_delete = []
            kept_count = 0

            for v in versions:
                if v.current_stage == "Production":
                    print(f"   ✅ Keeping Version {v.version} (Production)")
                elif kept_count < keep_last:
                    print(f"   ✅ Keeping Version {v.version} (recent)")
                    kept_count += 1
                else:
                    versions_to_delete.append(v)

            # Delete old versions
            if versions_to_delete:
                print(f"   🗑️  Deleting {len(versions_to_delete)} old versions...")
                for v in versions_to_delete:
                    try:
                        client.delete_model_version(
                            name=model.name,
                            version=v.version
                        )
                        print(f"      ✅ Deleted Version {v.version}")
                    except Exception as e:
                        print(f"      ❌ Failed to delete Version {v.version}: {e}")
            else:
                print("   ℹ️  No old versions to delete")

        print("\n✅ Cleanup completed!")
        return True

    except Exception as e:
        print(f"❌ Cleanup failed: {e}")
        return False


def list_models():
    """List all registered models."""
    mlflow.set_tracking_uri("mlruns")
    client = MlflowClient()

    print("📋 Registered Models:")
    print("=" * 80)

    models = client.search_registered_models()

    if not models:
        print("No models found in registry.")
        return

    for model in models:
        print(f"\n📦 {model.name}")

        # Get versions
        versions = client.search_model_versions(f"name='{model.name}'")
        versions.sort(key=lambda x: int(x.version), reverse=True)

        for v in versions:
            stage_emoji = "🏆" if v.current_stage == "Production" else "📌"
            print(f"   {stage_emoji} Version {v.version} - Stage: {v.current_stage}")

            # Get tags
            if v.tags:
                for key, value in v.tags.items():
                    print(f"      Tag: {key} = {value}")


def find_and_promote_best():
    """Find the model tagged as best and promote it."""
    mlflow.set_tracking_uri("mlruns")
    client = MlflowClient()

    print("🔍 Searching for best model...")

    try:
        # Get all registered models
        models = client.search_registered_models()

        if not models:
            print("❌ No models found in registry")
            return False

        # Look for model with best_model=true tag
        best_model = None
        best_version = None
        best_roc_auc = 0.0

        for model in models:
            # Get all versions
            versions = client.search_model_versions(f"name='{model.name}'")

            for v in versions:
                # Check if this version has best_model tag
                if v.tags and v.tags.get('best_model') == 'true':
                    roc_auc = float(v.tags.get('roc_auc', 0.0))
                    if roc_auc > best_roc_auc:
                        best_model = model.name
                        best_version = v.version
                        best_roc_auc = roc_auc

        if best_model:
            print(f"✅ Found best model: {best_model} v{best_version} (ROC-AUC: {best_roc_auc:.4f})")
            return promote_model(best_model, best_version)
        else:
            print("⚠️  No model found with 'best_model=true' tag")
            print("   Promoting latest version of first model...")
            # Fallback: promote latest version of first model
            first_model = models[0].name
            return promote_model(first_model)

    except Exception as e:
        print(f"❌ Error finding best model: {e}")
        return False


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python scripts/promote-model.py <model_name> [version]")
        print("\nOr use --list to see all models:")
        print("       python scripts/promote-model.py --list")
        print("\nOr use --auto to automatically find and promote best model:")
        print("       python scripts/promote-model.py --auto")
        print("\nOr use --cleanup to delete old model versions (keeps last 3):")
        print("       python scripts/promote-model.py --cleanup [model_name] [keep_count]")
        print("\nExamples:")
        print("  python scripts/promote-model.py heart-disease-logistic_regression")
        print("  python scripts/promote-model.py heart-disease-random_forest 2")
        print("  python scripts/promote-model.py --auto")
        print("  python scripts/promote-model.py --cleanup")
        print("  python scripts/promote-model.py --cleanup heart-disease-logistic_regression 5")
        sys.exit(1)

    if sys.argv[1] == "--list":
        list_models()
        sys.exit(0)

    if sys.argv[1] == "--auto":
        success = find_and_promote_best()
        sys.exit(0 if success else 1)

    if sys.argv[1] == "--cleanup":
        model_name = sys.argv[2] if len(sys.argv) > 2 else None
        keep_last = int(sys.argv[3]) if len(sys.argv) > 3 else 3

        # Confirm before cleanup
        if model_name:
            confirm = input(f"⚠️  Delete old versions of '{model_name}' (keeping last {keep_last})? [y/N]: ")
        else:
            confirm = input(f"⚠️  Delete old versions of ALL models (keeping last {keep_last})? [y/N]: ")

        if confirm.lower() == 'y':
            success = cleanup_old_versions(model_name, keep_last)
            sys.exit(0 if success else 1)
        else:
            print("❌ Cleanup cancelled")
            sys.exit(0)

    model_name = sys.argv[1]
    version = sys.argv[2] if len(sys.argv) > 2 else None

    success = promote_model(model_name, version)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

