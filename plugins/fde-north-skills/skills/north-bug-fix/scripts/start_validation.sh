#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: start_validation.sh SESSION_NAME URL [OUTPUT_DIR] [--browser BROWSER]

Start a headed Playwright validation session and begin video recording.

This wrapper delegates to the north-bug-triage skill's start_repro.sh so both
skills share the same headed-browser and video-recording setup.

Always pass the triage issue's playwright folder as OUTPUT_DIR, for example:
  start_validation.sh verify-attempt-1 https://example.com .triage-artifacts-fde-123/playwright
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
delegate="${script_dir}/../../north-bug-triage/scripts/start_repro.sh"

if [[ ! -f "$delegate" ]]; then
  echo "Expected helper script at $delegate" >&2
  exit 1
fi

exec bash "$delegate" "$@"
