#!/usr/bin/env bash
# Shared helper functions for interactive guide scripts.
# Source this file: SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" && source "$SCRIPT_DIR/../lib/helpers.sh"

# --- Colors and formatting ---
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

# --- Output helpers ---

header() {
  echo ""
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${BLUE}  $1${RESET}"
  echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
  echo ""
}

info() {
  echo -e "  ${GREEN}$1${RESET}"
}

warn() {
  echo -e "  ${YELLOW}$1${RESET}"
}

error() {
  echo -e "  ${RED}$1${RESET}"
}

explain() {
  echo -e "  $1"
}

show_cmd() {
  echo ""
  echo -e "  ${YELLOW}\$ $1${RESET}"
}

# --- Interactive helpers ---

prompt_continue() {
  echo ""
  read -rp "  Press Enter to continue..." </dev/tty
  echo ""
}

prompt_run() {
  local cmd="$1"
  show_cmd "$cmd"
  echo ""
  read -rp "  Press Enter to run..." </dev/tty
  echo -e "  ${CYAN}Running...${RESET}"
  echo ""
  eval "$cmd" 2> >(grep -v "Unable to use a TTY" >&2)
  echo ""
}

# --- Spinner ---

SPINNER_PID=""

start_spinner() {
  local msg="$1"
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  (
    while true; do
      for (( i=0; i<${#chars}; i++ )); do
        printf "\r  \033[0;36m%s\033[0m %s" "${chars:$i:1}" "$msg"
        sleep 0.1
      done
    done
  ) &
  SPINNER_PID=$!
}

stop_spinner() {
  if [[ -n "${SPINNER_PID:-}" ]]; then
    kill "$SPINNER_PID" 2>/dev/null || true
    wait "$SPINNER_PID" 2>/dev/null || true
    printf "\r\033[K"
    SPINNER_PID=""
  fi
}

# --- Prerequisite checks ---

require_cmd() {
  local cmd="$1"
  local install_hint="${2:-}"
  if ! command -v "$cmd" &>/dev/null; then
    error "Required command not found: $cmd"
    if [[ -n "$install_hint" ]]; then
      echo -e "  ${DIM}Install hint: $install_hint${RESET}"
    fi
    exit 1
  fi
}

# --- OS detection ---

detect_os() {
  # shellcheck disable=SC1091
  source /etc/os-release 2>/dev/null || true

  OS_ID="${ID:-unknown}"
  OS_VERSION="${VERSION_ID:-unknown}"
  OS_ARCH="$(uname -m)"

  # Determine OS family
  case "$OS_ID" in
    rhel|centos|rocky|almalinux|ol|fedora)
      OS_FAMILY="el"
      ;;
    debian)
      OS_FAMILY="debian"
      ;;
    ubuntu)
      OS_FAMILY="ubuntu"
      ;;
    *)
      OS_FAMILY="unknown"
      ;;
  esac

  # Major version (e.g. "22" from "22.04")
  OS_MAJOR="${OS_VERSION%%.*}"

  # Package manager
  case "$OS_FAMILY" in
    el)
      PKG_MGR="dnf"
      ;;
    debian|ubuntu)
      PKG_MGR="apt-get"
      ;;
    *)
      PKG_MGR="unknown"
      ;;
  esac

  export OS_ID OS_VERSION OS_ARCH OS_FAMILY OS_MAJOR PKG_MGR
}

# --- Cleanup trap ---

setup_trap() {
  trap 'stop_spinner' EXIT
}
