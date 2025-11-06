#!/usr/bin/env bash
# omarchy-install-all-themes-combined.sh
# Combined installer that fetches themes from both omarchythemes.com and learn.omacom.io
# Deduplicates and installs via omarchy-theme-install

set -u -o pipefail

# Configuration (overridable via environment)
OMARCHY_INSTALLER="${OMARCHY_INSTALLER:-${HOME}/.local/share/omarchy/bin/omarchy-theme-install}"
BASE_URL="${BASE_URL:-https://omarchythemes.com}"
LEARN_URL="${LEARN_URL:-https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes}"
DELAY="${DELAY:-0.5}"
STRICT_GITHUB="${STRICT_GITHUB:-0}"
LOG_FILE="${LOG_FILE:-/tmp/omarchy-theme-install-$(date +%Y%m%d-%H%M%S).log}"
USER_AGENT="${USER_AGENT:-OmarchyCombinedInstaller/1.0 (+https://omarchythemes.com) bash-curl}"
CURL_ARGS=(-fsSL -L --retry 2 --connect-timeout 10 --max-time 30 -A "$USER_AGENT")

# Runtime state
declare -a ALL_THEMES SELECTED_THEMES SUCCESS_THEMES FAIL_THEMES
MODE=""
ONLY_SLUGS=""
DRY_RUN=0
TMP_COMBINED="$(mktemp)"

trap 'rm -f "$TMP_COMBINED"' EXIT

# Terminal and color helpers
is_tty() { [[ -t 1 ]]; }
color() {
  if is_tty; then printf "%b" "$1"; else :; fi
}
RESET="$(color "\033[0m")"
GREEN="$(color "\033[32m")"
YELLOW="$(color "\033[33m")"
RED="$(color "\033[31m")"
BLUE="$(color "\033[34m")"

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
log() { printf "[%s] %s\n" "$(timestamp)" "$*" | tee -a "$LOG_FILE"; }
info() { log "${BLUE}[INFO]${RESET} $*"; }
warn() { log "${YELLOW}[WARN]${RESET} $*"; }
err()  { log "${RED}[ERROR]${RESET} $*"; }
ok()   { log "${GREEN}[OK]${RESET} $*"; }

usage() {
  cat <<'EOF'
Usage: omarchy-install-all-themes-combined.sh [options]

This script fetches themes from both omarchythemes.com and learn.omacom.io,
deduplicates them, and installs via omarchy-theme-install.

Options:
  -a, --all                 Install all discovered themes
  -i, --interactive         Choose themes interactively
  -o, --only SLUGS          Comma-separated list of theme slugs to install
  -l, --list                Only list discovered themes and exit
  -n, --dry-run             Do not install; just show what would be done
  -d, --delay SEC           Delay between requests (default: 0.5)
  --strict-github           Only accept root repo links (github.com/owner/repo)
  -h, --help                Show this help

If no mode option is provided, you will be prompted to choose.

Environment overrides:
  OMARCHY_INSTALLER, BASE_URL, LEARN_URL, DELAY, USER_AGENT, LOG_FILE, STRICT_GITHUB

Examples:
  omarchy-install-all-themes-combined.sh --list
  omarchy-install-all-themes-combined.sh --all
  omarchy-install-all-themes-combined.sh --interactive
  omarchy-install-all-themes-combined.sh --only dracula,catppuccin --dry-run
  DELAY=1.0 omarchy-install-all-themes-combined.sh --all
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Required command '$1' not found"; return 1; }
}

check_prereqs() {
  local ok=1
  for c in curl grep sed awk sort uniq tr; do
    require_cmd "$c" || ok=0
  done
  if [ ! -x "$OMARCHY_INSTALLER" ]; then
    err "Installer not found or not executable: $OMARCHY_INSTALLER"
    ok=0
  fi
  [ "$ok" -eq 1 ] || return 1
}

fetch() {
  local url="$1"
  local content
  if ! content=$(curl "${CURL_ARGS[@]}" -- "$url"); then
    return 1
  fi
  [[ -n "${DELAY:-}" ]] && sleep "$DELAY"
  printf "%s\n" "$content"
}

# ============================================================================
# Scraping functions from original omarchy-install-themes.sh
# ============================================================================

discover_theme_links() {
  local html
  if ! html=$(fetch "$BASE_URL"); then
    err "Failed to fetch $BASE_URL"
    return 1
  fi

  local links
  links=$(printf "%s\n" "$html" \
    | grep -Eo 'href="[^"]+"' \
    | cut -d'"' -f2 \
    | grep -E '(^/themes/|^https?://omarchythemes\.com/themes/)' \
    | sed -E 's|^/|'"$BASE_URL"'/|' \
    | sed -E 's|^https?://omarchythemes\.com|'"$BASE_URL"'|' \
    | sed -E 's|[#?].*$||' \
    | sort -u)

  if [ -z "$links" ]; then
    warn "No theme links found on $BASE_URL; trying $BASE_URL/themes"
    if ! html=$(fetch "$BASE_URL/themes"); then
      err "Failed to fetch $BASE_URL/themes"
      return 1
    fi
    links=$(printf "%s\n" "$html" \
      | grep -Eo 'href="[^"]+"' \
      | cut -d'"' -f2 \
      | grep -E '(^/themes/|^https?://[^/]+/themes/)' \
      | sed -E 's|^/|'"$BASE_URL"'/|' \
      | sed -E 's|^https?://[^/]+|'"$BASE_URL"'|' \
      | sed -E 's|[#?].*$||' \
      | sort -u)
  fi

  printf "%s\n" "$links" | grep -E '^https?://'
}

extract_github_url() {
  local repo=""
  repo=$(grep -Eoi 'href="https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/?(\.git)?"' \
    | head -n1 \
    | sed -E 's/^href="//; s/"$//; s|\.git$||; s|/+$||') || true

  if [ -z "$repo" ] && [ "${STRICT_GITHUB}" -eq 0 ]; then
    repo=$(grep -Eoi 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' \
      | head -n1 \
      | sed -E 's|/+$||')
  fi

  printf "%s\n" "$repo"
}

fetch_omarchythemes_themes() {
  local links
  if ! links=$(discover_theme_links); then
    warn "Failed to discover theme links from $BASE_URL"
    return 1
  fi

  local url page_html gh
  while read -r url; do
    [[ -z "$url" ]] && continue
    if ! page_html=$(fetch "$url" 2>/dev/null); then
      warn "Failed to fetch theme page: $url"
      continue
    fi
    if gh=$(printf "%s\n" "$page_html" | extract_github_url); then
      [[ -n "$gh" ]] && printf "%s\t%s\n" "$url" "$gh"
    fi
  done <<< "$links"
}

# ============================================================================
# Learn.omacom.io scraping
# ============================================================================

fetch_learn_omacom_themes() {
  local page
  if ! page=$(fetch "$LEARN_URL"); then
    warn "Failed to fetch from learn.omacom.io"
    return 1
  fi
  printf "%s\n" "$page" | grep -oP 'https://github\.com/[^"'\''\\s)]+' | sed -E 's|/+$||; s|\.git$||' | sort -u
}

# ============================================================================
# URL normalization and slug generation
# ============================================================================

normalize_github_url() {
  local in="$1"
  local u
  u=$(printf "%s" "$in" | tr '[:upper:]' '[:lower:]' | sed -E 's|^https?://(www\.)?github\.com/||; s|\.git$||; s|/*$||')
  
  local owner repo
  owner=$(printf "%s" "$u" | cut -d'/' -f1)
  repo=$(printf "%s" "$u" | cut -d'/' -f2)
  
  if [[ -z "$owner" || -z "$repo" ]]; then
    return 1
  fi
  
  printf "https://github.com/%s/%s\n" "$owner" "$repo"
}

slugify_repo() {
  local url="$1"
  local path
  path=$(printf "%s\n" "$url" | sed -E 's|^https?://(www\.)?github\.com/||')
  local owner repo
  owner=$(printf "%s" "$path" | cut -d'/' -f1)
  repo=$(printf "%s" "$path" | cut -d'/' -f2)
  printf "%s-%s\n" "$owner" "$repo" | sed -E 's|[^a-z0-9._-]|-|g'
}

# ============================================================================
# Deduplication
# ============================================================================

deduplicate_themes() {
  declare -A seen=()
  declare -A slug_count=()
  
  while IFS='|' read -r slug url source; do
    [[ -z "$url" ]] && continue
    local norm
    if ! norm=$(normalize_github_url "$url" 2>/dev/null); then
      warn "Skipping malformed GitHub URL: $url"
      continue
    fi
    
    if [[ -n "${seen[$norm]:-}" ]]; then
      continue
    fi
    
    # Handle slug collisions
    local final_slug="$slug"
    if [[ -n "${slug_count[$slug]:-}" ]]; then
      local count=$((slug_count[$slug] + 1))
      slug_count[$slug]=$count
      final_slug="${slug}-${count}"
    else
      slug_count[$slug]=1
    fi
    
    seen[$norm]="$final_slug|$norm|$source"
  done
  
  for k in "${!seen[@]}"; do
    printf "%s\n" "${seen[$k]}"
  done | sort
}

# ============================================================================
# Interactive selection
# ============================================================================

have_fzf() { command -v fzf >/dev/null 2>&1; }

parse_numbered_selection() {
  local input="$1"
  local picks="$2"
  
  # Split on comma and spaces
  local -a selections
  IFS=',' read -ra selections <<< "$picks"
  
  for sel in "${selections[@]}"; do
    sel=$(echo "$sel" | tr -d ' ')
    if [[ "$sel" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      # Range
      local start="${BASH_REMATCH[1]}"
      local end="${BASH_REMATCH[2]}"
      for ((i=start; i<=end; i++)); do
        sed -n "${i}p" <<< "$input"
      done
    elif [[ "$sel" =~ ^[0-9]+$ ]]; then
      # Single number
      sed -n "${sel}p" <<< "$input"
    fi
  done
}

choose_themes_interactive() {
  local input
  input=$(printf "%s\n" "${ALL_THEMES[@]}")
  
  if have_fzf; then
    local selected
    selected=$(printf "%s\n" "$input" | awk -F'|' '{printf "%s\t%s\t%s\n",$1,$2,$3}' | \
      fzf -m --with-nth=1,3 --prompt="Select themes > " --header="TAB to multi-select; ENTER to confirm" || true)
    printf "%s\n" "$selected" | awk -F'\t' '{printf "%s|%s|%s\n",$1,$2,$3}'
  else
    echo "Available themes:" >&2
    nl -ba <<< "$input" | sed -E 's/\|/ | /g' >&2
    echo "" >&2
    echo "Enter numbers to install (e.g. 1,2,5-7), or press Enter to cancel:" >&2
    local picks
    read -r picks
    [[ -z "$picks" ]] && return 0
    parse_numbered_selection "$input" "$picks"
  fi
}

# ============================================================================
# Mode prompt
# ============================================================================

prompt_for_mode() {
  local tries=0 choice
  while (( tries < 3 )); do
    echo ""
    echo "No installation mode specified. Choose an option:"
    echo "1) Install all themes automatically"
    echo "2) Interactive selection (choose specific themes)"
    echo "3) List themes only"
    echo ""
    read -r -p "Enter your choice (1-3): " choice
    case "$choice" in
      1) MODE="all"; return 0 ;;
      2) MODE="interactive"; return 0 ;;
      3) MODE="list"; return 0 ;;
      *) err "Invalid choice: $choice"; tries=$((tries+1)) ;;
    esac
  done
  err "Too many invalid attempts. Exiting."
  exit 2
}

# ============================================================================
# CLI parsing
# ============================================================================

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -a|--all) MODE="all"; shift ;;
      -i|--interactive) MODE="interactive"; shift ;;
      -o|--only) ONLY_SLUGS="$2"; MODE="only"; shift 2 ;;
      -l|--list) MODE="list"; shift ;;
      -n|--dry-run) DRY_RUN=1; shift ;;
      -d|--delay) DELAY="$2"; shift 2 ;;
      --strict-github) STRICT_GITHUB=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown option: $1"; usage; exit 2 ;;
    esac
  done
}

# ============================================================================
# Installation loop
# ============================================================================

run_mode() {
  case "$MODE" in
    list)
      printf "%s\n" "${ALL_THEMES[@]}" | awk -F'|' '{printf "%-40s %-50s %-20s\n", $1, $2, $3}'
      exit 0
      ;;
    all)
      SELECTED_THEMES=("${ALL_THEMES[@]}")
      ;;
    only)
      local -a slugs
      IFS=',' read -ra slugs <<< "$ONLY_SLUGS"
      for s in "${slugs[@]}"; do
        local s_trim
        s_trim=$(printf "%s" "$s" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
        for theme in "${ALL_THEMES[@]}"; do
          local slug
          slug=$(printf "%s" "$theme" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]')
          if [[ "$slug" == "$s_trim" ]]; then
            SELECTED_THEMES+=("$theme")
            break
          fi
        done
      done
      if [ "${#SELECTED_THEMES[@]}" -eq 0 ]; then
        warn "No matching themes found for: $ONLY_SLUGS"
        exit 0
      fi
      ;;
    interactive)
      mapfile -t SELECTED_THEMES < <(choose_themes_interactive)
      if [ "${#SELECTED_THEMES[@]}" -eq 0 ]; then
        warn "No themes selected. Nothing to do."
        exit 0
      fi
      ;;
    *)
      err "Invalid mode: $MODE"
      exit 2
      ;;
  esac

  info "Preparing to process ${#SELECTED_THEMES[@]} theme(s). Delay between installs: ${DELAY}s"
  [ "$DRY_RUN" -eq 1 ] && warn "Dry-run enabled. Will not install themes."

  local idx=0
  local total=${#SELECTED_THEMES[@]}

  for theme in "${SELECTED_THEMES[@]}"; do
    idx=$((idx+1))
    local slug url source
    IFS='|' read -r slug url source <<< "$theme"
    
    printf "\n" >> "$LOG_FILE"
    info "[$idx/$total] Processing: $slug (from $source)"
    info "[$idx/$total] GitHub URL: $url"

    if [ "$DRY_RUN" -eq 1 ]; then
      ok "[$slug] DRY RUN - Skipped install"
      SUCCESS_THEMES+=("$slug")
      continue
    fi

    if "$OMARCHY_INSTALLER" "$url" >>"$LOG_FILE" 2>&1; then
      ok "[$slug] Installed successfully"
      SUCCESS_THEMES+=("$slug")
    else
      err "[$slug] Installation failed (see log: $LOG_FILE)"
      FAIL_THEMES+=("$slug")
    fi
    
    [[ -n "${DELAY:-}" ]] && sleep "$DELAY"
  done
}

# ============================================================================
# Summary report
# ============================================================================

print_summary() {
  printf "\n" >> "$LOG_FILE"
  info "========================================="
  info "Installation Summary"
  info "========================================="
  info "Total unique themes discovered: ${#ALL_THEMES[@]}"
  info "Themes processed: ${#SELECTED_THEMES[@]}"
  info "Successful installations: ${#SUCCESS_THEMES[@]}"
  info "Failed installations: ${#FAIL_THEMES[@]}"
  
  if [ "${#FAIL_THEMES[@]}" -gt 0 ]; then
    warn "Failed themes:"
    for f in "${FAIL_THEMES[@]}"; do
      warn "  - $f"
    done
  fi
  
  info "Log file: $LOG_FILE"
  info "========================================="
}

# ============================================================================
# Main
# ============================================================================

main() {
  check_prereqs || { err "Prerequisite check failed"; exit 1; }
  parse_args "$@"
  
  info "Combined Omarchy Theme Installer"
  info "Log file: $LOG_FILE"
  info "Fetching themes from multiple sources..."

  local a_count=0 b_count=0

  # Fetch from omarchythemes.com
  if om_out=$(fetch_omarchythemes_themes 2>&1); then
    while IFS=$'\t' read -r page gh; do
      [[ -z "$gh" ]] && continue
      local norm slug
      if norm=$(normalize_github_url "$gh" 2>/dev/null); then
        slug=$(slugify_repo "$norm")
        printf "%s|%s|%s\n" "$slug" "$norm" "omarchythemes.com"
      fi
    done <<< "$om_out" >> "$TMP_COMBINED"
    a_count=$(grep -c 'omarchythemes.com' "$TMP_COMBINED" 2>/dev/null || echo 0)
    info "Found $a_count themes from omarchythemes.com"
  else
    warn "Failed to collect from omarchythemes.com"
  fi

  # Fetch from learn.omacom.io
  if learn_out=$(fetch_learn_omacom_themes 2>&1); then
    while read -r gh; do
      [[ -z "$gh" ]] && continue
      local norm slug
      if norm=$(normalize_github_url "$gh" 2>/dev/null); then
        slug=$(slugify_repo "$norm")
        printf "%s|%s|%s\n" "$slug" "$norm" "learn.omacom.io"
      fi
    done <<< "$learn_out" >> "$TMP_COMBINED"
    b_count=$(grep -c 'learn.omacom.io' "$TMP_COMBINED" 2>/dev/null || echo 0)
    info "Found $b_count themes from learn.omacom.io"
  else
    warn "Failed to collect from learn.omacom.io"
  fi

  if (( a_count + b_count == 0 )); then
    err "No themes discovered from either source."
    exit 1
  fi

  # Deduplicate
  mapfile -t ALL_THEMES < <(deduplicate_themes < "$TMP_COMBINED")
  info "Total unique themes after deduplication: ${#ALL_THEMES[@]}"

  # Resolve mode and run
  [[ -z "${MODE:-}" ]] && prompt_for_mode
  run_mode
  print_summary
}

main "$@"
