#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
python3 tool/ci/validate_ios_workflow_secrets.py
