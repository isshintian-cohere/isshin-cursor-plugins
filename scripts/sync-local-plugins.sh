#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ROOT="${REPO_ROOT}/plugins"
DEST_ROOT="${HOME}/.cursor/plugins/local"

if [[ ! -d "${SOURCE_ROOT}" ]]; then
  echo "Source plugins directory not found: ${SOURCE_ROOT}" >&2
  exit 1
fi

mkdir -p "${DEST_ROOT}"
shopt -s nullglob

copied_count=0
skipped_count=0

for plugin_dir in "${SOURCE_ROOT}"/*; do
  [[ -d "${plugin_dir}" ]] || continue

  plugin_name="$(basename "${plugin_dir}")"

  case "${plugin_name}" in
    starter-simple|starter-advanced|starter-*)
      echo "Skipping ${plugin_name} (starter plugin)"
      skipped_count=$((skipped_count + 1))
      continue
      ;;
  esac

  if [[ ! -f "${plugin_dir}/.cursor-plugin/plugin.json" ]]; then
    echo "Skipping ${plugin_name} (missing .cursor-plugin/plugin.json)"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  dest_dir="${DEST_ROOT}/${plugin_name}"
  rm -rf "${dest_dir}"
  cp -R "${plugin_dir}" "${dest_dir}"

  echo "Copied ${plugin_name} -> ${dest_dir}"
  copied_count=$((copied_count + 1))
done

echo "Done. Copied ${copied_count} plugin(s); skipped ${skipped_count}."
