#!/usr/bin/env bash
set -euo pipefail

# Versioned filename for archival
tar -czf "${REPO_NAME}-${TAG_NAME}.crbl" \
  data default package.json README.md
# Fixed filename for latest-download URLs
cp "${REPO_NAME}-${TAG_NAME}.crbl" "${REPO_NAME}.crbl"
