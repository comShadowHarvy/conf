#!/usr/bin/env bash
# omarchy-install-themes.sh
# Scrapes https://omarchythemes.com for theme pages, extracts GitHub repo URLs,
# and installs them via omarchy-theme-install, with progress, selection, and error handling.

set -u -o pipefail

OMARCHY_INSTALLER="${OMARCHY_INSTALLER:-/home/me/.local/share/omarchy/bin/omarchy-theme-install}"
BASE_URL="${BASE_URL:-https://omarchythemes.com}"
DELAY="${DELAY:-0.3}"
STRICT_GITHUB="${STRICT_GITHUB:-0}"  # 1 = require root repo link only
USER_AGENT="${USER_AGENT:-Mozilla/5.0 (X11; Linux x86_64; omarchy-theme-scraper/1.0)}"
LOG_FILE="${LOG_FILE:-/tmp/omarchy-theme-install-$(date +%Y%m%d-%H%M%S).log}"

CURL_ARGS=(-fsSL --max-time 25 --retry 2 --retry-delay 1 --retry-all-errors -A "$USER_AGENT")

is_tty() { [ -t 1 ]; }
color() {
  if is_tty; then printf "%b" "$1"; else :; fi
}
reset="$(color "\033[0m")"
green="$(color "\033[32m")"
yellow="$(color "\033[33m")"
red="$(color "\033[31m")"
blue="$(color "\033[34m")"

log() { printf "%s\n" "$*" | tee -a "$LOG_FILE"; }
info() { log "${blue}[INFO]${reset} $*"; }
warn() { log "${yellow}[WARN]${reset} $*"; }
err()  { log "${red}[ERROR]${reset} $*"; }
ok()   { log "${green}[OK]${reset} $*"; }

usage() {
  cat <<'EOF'
Usage: omarchy-install-themes.sh [options]

Options:
  -a, --all                 Install all discovered themes
  -i, --interactive         Choose themes interactively (default if no --all/--only)
  -o, --only SLUGS          Comma-separated list of theme slugs to install (e.g. catppuccin,dracula)
  -l, --list                Only list discovered themes and exit
  -n, --dry-run             Do not install; just show what would be done
  -d, --delay SEC           Delay between requests (default: 0.3)
  --strict-github           Only accept root repo links (github.com/owner/repo). Otherwise fallback to first github link.
  -h, --help                Show this help

Environment overrides:
  OMARCHY_INSTALLER, BASE_URL, DELAY, USER_AGENT, LOG_FILE, STRICT_GITHUB

Examples:
  omarchy-install-themes.sh --list
  omarchy-install-themes.sh --only catppuccin,dracula
  omarchy-install-themes.sh --all
  omarchy-install-themes.sh --interactive
  DELAY=0.1 omarchy-install-themes.sh --all
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
  # $1 URL
  local url="$1"
  local content
  if ! content=$(curl "${CURL_ARGS[@]}" -- "$url"); then
    return 1
  fi
  printf "%s\n" "$content"
}

discover_theme_links() {
  # Print absolute theme URLs, one per line
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

slug_from_url() {
  # $1 URL; prints last path segment
  printf "%s\n" "$1" | awk -F'/' '{ gsub(/\/+$/,"",$0); print $NF }'
}

extract_github_url() {
  # stdin: theme page html
  # prints github repo URL or empty
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

have_fzf() { command -v fzf >/dev/null 2>&1; }

choose_themes_interactive() {
  # stdin: lines "slug url"; prints selected urls
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"

  if have_fzf; then
    fzf --ansi --multi --prompt="Select themes to install (TAB to select, ENTER to confirm): " --height=90% --border < "$tmp" \
      | awk '{print $2}'
  else
    nl -w2 -s') ' "$tmp" >&2
    echo >&2
    printf "Enter numbers separated by spaces, 'a' for all, or empty to cancel: " >&2
    read -r selection
    if [ "$selection" = "a" ] || [ "$selection" = "A" ]; then
      awk '{print $2}' "$tmp"
    elif [ -n "$selection" ]; then
      for n in $selection; do sed -n "${n}p" "$tmp"; done | awk '{print $2}'
    fi
  fi

  rm -f "$tmp"
}

main() {
  local mode="interactive"
  local only_slugs=""
  local dry_run=0
  local list_only=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -a|--all) mode="all"; shift ;;
      -i|--interactive) mode="interactive"; shift ;;
      -o|--only) only_slugs="$2"; mode="only"; shift 2 ;;
      -l|--list) list_only=1; shift ;;
      -n|--dry-run) dry_run=1; shift ;;
      -d|--delay) DELAY="$2"; shift 2 ;;
      --strict-github) STRICT_GITHUB=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown option: $1"; usage; exit 2 ;;
    esac
  done

  check_prereqs || { err "Prerequisite check failed"; exit 1; }
  info "Log file: $LOG_FILE"

  mapfile -t theme_urls < <(discover_theme_links || true)
  if [ "${#theme_urls[@]}" -eq 0 ]; then
    err "No themes discovered at $BASE_URL"
    exit 1
  fi

  declare -A slug_to_url
  declare -a all_pairs
  for u in "${theme_urls[@]}"; do
    slug=$(slug_from_url "$u")
    slug_to_url["$slug"]="$u"
    all_pairs+=("$slug $u")
  done

  if [ "$list_only" -eq 1 ]; then
    printf "%s\n" "${all_pairs[@]}" | sort
    exit 0
  fi

  declare -a selected_urls
  case "$mode" in
    all)
      selected_urls=("${theme_urls[@]}")
      ;;
    only)
      IFS=',' read -r -a slugs <<< "$only_slugs"
      for s in "${slugs[@]}"; do
        s_trim=$(printf "%s" "$s" | tr -d ' ')
        u="${slug_to_url[$s_trim]:-}"
        if [ -z "$u" ]; then
          warn "Slug not found: $s_trim"
        else
          selected_urls+=("$u")
        fi
      done
      ;;
    interactive|*)
      printf "%s\n" "${all_pairs[@]}" | choose_themes_interactive > /tmp/omarchy-themes-selected.$$
      mapfile -t selected_urls < /tmp/omarchy-themes-selected.$$
      rm -f /tmp/omarchy-themes-selected.$$
      ;;
  esac

  if [ "${#selected_urls[@]}" -eq 0 ]; then
    warn "No themes selected. Nothing to do."
    exit 0
  fi

  info "Preparing to process ${#selected_urls[@]} theme(s). Delay between requests: ${DELAY}s"
  [ "$dry_run" -eq 1 ] && warn "Dry-run enabled. Will not install themes."

  successes=()
  failures=()
  idx=0
  total=${#selected_urls[@]}

  for theme_url in "${selected_urls[@]}"; do
    idx=$((idx+1))
    slug=$(slug_from_url "$theme_url")
    printf "\n" >> "$LOG_FILE"
    info "[$idx/$total] Processing theme: $slug ($theme_url)"
    sleep "$DELAY"

    page_html=""
    if ! page_html=$(fetch "$theme_url"); then
      warn "[$slug] Failed to fetch theme page"
      failures+=("$slug: fetch_failed")
      continue
    fi

    github_url=$(printf "%s\n" "$page_html" | extract_github_url)
    if [ -z "$github_url" ]; then
      warn "[$slug] No GitHub repository link found on theme page"
      failures+=("$slug: no_github_link")
      continue
    fi

    info "[$slug] Installing from $github_url"
    if [ "$dry_run" -eq 1 ]; then
      ok "[$slug] DRY RUN - Skipped install"
      successes+=("$slug: dry_run")
      continue
    fi

    if "$OMARCHY_INSTALLER" "$github_url" >>"$LOG_FILE" 2>&1; then
      ok "[$slug] Installed successfully"
      successes+=("$slug")
    else
      err "[$slug] Installation failed (see log: $LOG_FILE)"
      failures+=("$slug: install_failed")
      continue
    fi
  done

  printf "\n" >> "$LOG_FILE"
  info "Done. ${#successes[@]} succeeded; ${#failures[@]} failed."
  if [ "${#failures[@]}" -gt 0 ]; then
    warn "Failures:"
    for f in "${failures[@]}"; do
      warn "  - $f"
    done
  fi
}

main "$@"
