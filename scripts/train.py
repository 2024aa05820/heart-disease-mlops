#!/usr/bin/env python3
"""
Training script entry point.

Usage:
    python scripts/train.py
    python scripts/train.py --config path/to/config.yaml
"""

import argparse
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.models.train import train_all_models  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Train heart disease classification models")
    parser.add_argument(
        "--config",
        type=str,
        default="src/config/config.yaml",
        help="Path to configuration file"
    )
    args = parser.parse_args()
    
    train_all_models(args.config)


if __name__ == "__main__":
    main()


