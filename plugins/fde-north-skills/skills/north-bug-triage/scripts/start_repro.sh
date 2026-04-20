#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: start_repro.sh SESSION_NAME URL [OUTPUT_DIR] [--browser BROWSER]

Open a headed Playwright session, verify it is visible, and start video recording.

Examples:
  start_repro.sh stg-bug https://stg.demo.cloud.cohere.com/
  start_repro.sh admin-flow https://example.com ./triage-artifacts/admin-flow --browser chrome
EOF
}

browser="chrome"
session_name=""
target_url=""
output_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --browser)
      if [[ $# -lt 2 ]]; then
        echo "--browser requires a value." >&2
        exit 1
      fi
      browser="$2"
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
      if [[ -z "$session_name" ]]; then
        session_name="$1"
      elif [[ -z "$target_url" ]]; then
        target_url="$1"
      elif [[ -z "$output_dir" ]]; then
        output_dir="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$session_name" || -z "$target_url" ]]; then
  usage >&2
  exit 1
fi

if [[ -z "$output_dir" ]]; then
  output_dir="${PWD}/.triage-artifacts-${session_name}/playwright"
fi

if command -v playwright-cli >/dev/null 2>&1; then
  PLAYWRIGHT_CMD=(playwright-cli)
elif command -v npx >/dev/null 2>&1 && npx --no-install playwright-cli --version >/dev/null 2>&1; then
  PLAYWRIGHT_CMD=(npx --no-install playwright-cli)
else
  echo "playwright-cli is required but was not found globally or via npx." >&2
  exit 1
fi

mkdir -p "$output_dir"
profile_dir="${output_dir}/profile"
mkdir -p "$profile_dir"

timestamp="$(date +%Y%m%d-%H%M%S)"
video_path="${output_dir}/${session_name}-${timestamp}.webm"

# Start each repro from a clean named session so the video and browser state line up.
"${PLAYWRIGHT_CMD[@]}" -s="$session_name" close >/dev/null 2>&1 || true

open_output="$("${PLAYWRIGHT_CMD[@]}" -s="$session_name" open --browser="$browser" --headed --profile="$profile_dir" "$target_url" 2>&1)" || {
  printf '%s\n' "$open_output" >&2
  exit 1
}

if command -v osascript >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
  case "$browser" in
    chrome)
      osascript -e 'tell application "Google Chrome" to activate' >/dev/null 2>&1 || true
      ;;
    msedge)
      osascript -e 'tell application "Microsoft Edge" to activate' >/dev/null 2>&1 || true
      ;;
  esac
fi

list_output="$("${PLAYWRIGHT_CMD[@]}" list 2>&1)" || {
  printf '%s\n' "$list_output" >&2
  exit 1
}

if ! awk -v session="$session_name" '
  $0 == "- " session ":" { in_session = 1; next }
  in_session && $0 ~ /^- / { exit }
  in_session && $0 ~ /headed: true/ { found = 1 }
  END { exit found ? 0 : 1 }
' <<<"$list_output"; then
  echo "Expected a headed Playwright session, but could not verify it." >&2
  printf '%s\n' "$list_output" >&2
  exit 1
fi

start_video() {
  "${PLAYWRIGHT_CMD[@]}" -s="$session_name" video-start "$video_path"
}

video_output="$(start_video 2>&1)" || {
  if [[ "$video_output" == *"ffmpeg"* ]]; then
    if ! command -v npx >/dev/null 2>&1; then
      echo "Video recording needs ffmpeg, and npx is not available to install it." >&2
      exit 1
    fi
    npx playwright install ffmpeg >&2
    video_output="$(start_video 2>&1)" || {
      printf '%s\n' "$video_output" >&2
      exit 1
    }
  else
    printf '%s\n' "$video_output" >&2
    exit 1
  fi
}

cat <<EOF
Started headed repro session:
- Session: ${session_name}
- Browser: ${browser}
- URL: ${target_url}
- Profile: ${profile_dir}
- Video: ${video_path}
- Triage folder: $(dirname "$output_dir")

Continue with:
- ${PLAYWRIGHT_CMD[*]} -s=${session_name} snapshot
- ${PLAYWRIGHT_CMD[*]} -s=${session_name} click <ref>

When done:
- ${PLAYWRIGHT_CMD[*]} -s=${session_name} video-stop
- ${PLAYWRIGHT_CMD[*]} -s=${session_name} close
- Write report to: $(dirname "$output_dir")/REPORT.md
EOF
