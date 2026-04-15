#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ROOT="${REPO_ROOT}/plugins"
DEST_ROOT="${HOME}/.cursor/plugins/local"

usage() {
  cat <<EOF
Usage: $(basename "$0") <install|uninstall>

Modes:
  install    Copy selected plugins from plugins/ to ${DEST_ROOT}
  uninstall  Remove selected plugins from ${DEST_ROOT}
EOF
}

is_starter_plugin() {
  case "$1" in
    starter-simple|starter-advanced|starter-*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

contains_value() {
  local needle="$1"
  shift

  local value
  for value in "$@"; do
    if [[ "${value}" == "${needle}" ]]; then
      return 0
    fi
  done

  return 1
}

discover_source_plugins() {
  local plugin_dir
  local plugin_name

  SOURCE_PLUGINS=()

  for plugin_dir in "${SOURCE_ROOT}"/*; do
    [[ -d "${plugin_dir}" ]] || continue

    plugin_name="$(basename "${plugin_dir}")"

    if is_starter_plugin "${plugin_name}"; then
      continue
    fi

    if [[ ! -f "${plugin_dir}/.cursor-plugin/plugin.json" ]]; then
      echo "Skipping ${plugin_name} (missing .cursor-plugin/plugin.json)"
      continue
    fi

    SOURCE_PLUGINS+=("${plugin_name}")
  done
}

discover_installed_plugins() {
  local plugin_name

  INSTALLED_PLUGINS=()

  for plugin_name in "${SOURCE_PLUGINS[@]}"; do
    if [[ -d "${DEST_ROOT}/${plugin_name}" ]]; then
      INSTALLED_PLUGINS+=("${plugin_name}")
    fi
  done
}

print_plugin_list() {
  local title="$1"
  shift
  local plugins=("$@")
  local i
  local plugin_name
  local suffix

  echo "${title}"

  for ((i = 0; i < ${#plugins[@]}; i++)); do
    plugin_name="${plugins[i]}"
    suffix=""

    if [[ -d "${DEST_ROOT}/${plugin_name}" ]]; then
      suffix=" [installed]"
    fi

    printf "  %d) %s%s\n" "$((i + 1))" "${plugin_name}" "${suffix}"
  done
}

prompt_for_selection() {
  local mode="$1"
  shift
  local options=("$@")
  local input
  local tokens=()
  local token
  local index
  local selected=()

  while true; do
    if [[ "${mode}" == "install" ]]; then
      read -r -p "Enter plugins to install (e.g. \"1,2\"), or 'all': " input
    else
      read -r -p "Enter plugins to uninstall (e.g. \"1,2\"), or 'all': " input
    fi

    if [[ "${input}" == "all" ]]; then
      SELECTED_PLUGINS=("${options[@]}")
      return 0
    fi

    if [[ ! "${input}" =~ ^[[:space:]]*[0-9]+([[:space:]]*,[[:space:]]*[0-9]+)*[[:space:]]*$ ]]; then
      echo "Invalid selection format. Use a comma-delimited list like '1,2' or 'all'."
      continue
    fi

    IFS=',' read -r -a tokens <<< "${input}"

    if [[ ${#tokens[@]} -eq 0 ]]; then
      echo "No selection provided. Try again."
      continue
    fi

    selected=()

    for token in "${tokens[@]}"; do
      token="${token#"${token%%[![:space:]]*}"}"
      token="${token%"${token##*[![:space:]]}"}"

      if [[ ! "${token}" =~ ^[0-9]+$ ]]; then
        echo "Invalid selection '${token}'. Use numbers or 'all'."
        selected=()
        break
      fi

      index=$((token - 1))

      if ((index < 0 || index >= ${#options[@]})); then
        echo "Selection '${token}' is out of range."
        selected=()
        break
      fi

      if ! contains_value "${options[index]}" "${selected[@]}"; then
        selected+=("${options[index]}")
      fi
    done

    if [[ ${#selected[@]} -gt 0 ]]; then
      SELECTED_PLUGINS=("${selected[@]}")
      return 0
    fi
  done
}

if [[ ! -d "${SOURCE_ROOT}" ]]; then
  echo "Source plugins directory not found: ${SOURCE_ROOT}" >&2
  exit 1
fi

shopt -s nullglob

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

MODE="$1"

case "${MODE}" in
  install|uninstall)
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

discover_source_plugins

if [[ ${#SOURCE_PLUGINS[@]} -eq 0 ]]; then
  echo "No installable plugins found in ${SOURCE_ROOT}."
  exit 0
fi

if [[ "${MODE}" == "install" ]]; then
  mkdir -p "${DEST_ROOT}"
  print_plugin_list "Available plugins:" "${SOURCE_PLUGINS[@]}"
  prompt_for_selection "${MODE}" "${SOURCE_PLUGINS[@]}"

  processed_count=0
  for plugin_name in "${SELECTED_PLUGINS[@]}"; do
    dest_dir="${DEST_ROOT}/${plugin_name}"
    rm -rf "${dest_dir}"
    cp -R "${SOURCE_ROOT}/${plugin_name}" "${dest_dir}"

    echo "Installed ${plugin_name} -> ${dest_dir}"
    processed_count=$((processed_count + 1))
  done

  echo "Done. Installed ${processed_count} plugin(s)."
  exit 0
fi

discover_installed_plugins

if [[ ${#INSTALLED_PLUGINS[@]} -eq 0 ]]; then
  echo "No managed local plugins found in ${DEST_ROOT}."
  exit 0
fi

print_plugin_list "Installed local plugins:" "${INSTALLED_PLUGINS[@]}"
prompt_for_selection "${MODE}" "${INSTALLED_PLUGINS[@]}"

processed_count=0
for plugin_name in "${SELECTED_PLUGINS[@]}"; do
  dest_dir="${DEST_ROOT}/${plugin_name}"
  rm -rf "${dest_dir}"

  echo "Uninstalled ${plugin_name} from ${dest_dir}"
  processed_count=$((processed_count + 1))
done

echo "Done. Uninstalled ${processed_count} plugin(s)."
