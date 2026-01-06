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
import os
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import mlflow
from mlflow.tracking import MlflowClient


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
            print(f"\nAvailable models:")
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
                print(f"\nAvailable versions:")
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
        print(f"\n📦 Checking for existing Production versions...")
        production_versions = client.get_latest_versions(model_name, stages=["Production"])
        
        for pv in production_versions:
            print(f"   Archiving version {pv.version}...")
            try:
                client.transition_model_version_stage(
                    name=model_name,
                    version=pv.version,
                    stage="Archived"
                )
                print(f"   ✅ Version {pv.version} archived")
            except Exception as e:
                print(f"   ⚠️  Could not archive version {pv.version}: {e}")
        
        # Promote to Production
        print(f"\n🚀 Promoting version {target_version} to Production...")
        
        try:
            client.transition_model_version_stage(
                name=model_name,
                version=target_version,
                stage="Production"
            )
            print(f"✅ Successfully promoted {model_name} v{target_version} to Production!")
            return True
            
        except Exception as e:
            print(f"❌ Failed to promote model: {type(e).__name__}")
            print(f"   Error: {str(e)[:200]}")
            print(f"\n💡 Manual promotion steps:")
            print(f"   1. Open MLflow UI: http://localhost:5001")
            print(f"   2. Go to Models tab")
            print(f"   3. Click '{model_name}'")
            print(f"   4. Click 'Version {target_version}'")
            print(f"   5. Change Stage dropdown to 'Production'")
            print(f"   6. Click 'Save'")
            return False
            
    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
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


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python scripts/promote-model.py <model_name> [version]")
        print("\nOr use --list to see all models:")
        print("       python scripts/promote-model.py --list")
        print("\nExamples:")
        print("  python scripts/promote-model.py heart-disease-logistic_regression")
        print("  python scripts/promote-model.py heart-disease-random_forest 2")
        sys.exit(1)
    
    if sys.argv[1] == "--list":
        list_models()
        sys.exit(0)
    
    model_name = sys.argv[1]
    version = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = promote_model(model_name, version)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

