#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: fetch_linear_context.sh ISSUE_ID [TRIAGE_DIR] [--workspace WORKSPACE]

Fetch Linear issue context for the Explore step.
Writes a single consolidated Markdown file at TRIAGE_DIR/linear-context.md
with sections: Metadata, Artifact Index, Description, Comments.
TRIAGE_DIR defaults to ./.triage-artifacts-<issue_id_lower>/.
Uses Linear JSON only as a temporary intermediate and cleans it up automatically.
By default this keeps remote file URLs and does not download attachments.
EOF
}

if ! command -v linear >/dev/null 2>&1; then
  echo "linear CLI is required but was not found in PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but was not found in PATH." >&2
  exit 1
fi

workspace=""
issue_id=""
triage_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --workspace)
      if [[ $# -lt 2 ]]; then
        echo "--workspace requires a value." >&2
        exit 1
      fi
      workspace="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$issue_id" ]]; then
        issue_id="$1"
      elif [[ -z "$triage_dir" ]]; then
        triage_dir="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$issue_id" ]]; then
  usage >&2
  exit 1
fi

if [[ -z "$triage_dir" ]]; then
  issue_id_lower="$(echo "$issue_id" | tr '[:upper:]' '[:lower:]')"
  triage_dir="${PWD}/.triage-artifacts-${issue_id_lower}"
fi

mkdir -p "$triage_dir"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

context_md="${triage_dir}/linear-context.md"
issue_json="$(mktemp "${TMPDIR:-/tmp}/fetch_linear_context.issue.XXXXXX")"
comments_json="$(mktemp "${TMPDIR:-/tmp}/fetch_linear_context.comments.XXXXXX")"

cleanup() {
  rm -f "$issue_json" "$comments_json"
}

trap cleanup EXIT

issue_cmd=(linear issue view "$issue_id" --json --no-comments --no-download)
comments_cmd=(linear issue comment list "$issue_id" --json)

if [[ -n "$workspace" ]]; then
  issue_cmd+=(--workspace "$workspace")
  comments_cmd+=(--workspace "$workspace")
fi

"${issue_cmd[@]}" > "$issue_json"
"${comments_cmd[@]}" > "$comments_json"

python3 "${script_dir}/fetch_linear_context.py" \
  "$issue_json" \
  "$comments_json" \
  "$context_md"

cat <<EOF
Saved Linear context for ${issue_id}:
- ${context_md}

Triage folder: ${triage_dir}
Note: attachments were not downloaded. Use the Linear CLI directly later in Triage if artifact download becomes necessary.
EOF
