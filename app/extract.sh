#!/usr/bin/env bash
#=====================================================================
#  extract-all.sh  –  Extract any supported archive type into a new folder
#=====================================================================
#
#  Usage:
#      ./extract-all.sh <archive1> [<archive2> ...]
#
#  The script creates a sub‑directory called
#     <basename>_extracted
#  next to the archive file and extracts the content there.
#
#  Supported formats (with a short list of tools needed):
#      * .zip          → unzip
#      * .tar          → tar
#      * .tar.gz/.tgz  → tar -xzf
#      * .tar.bz2/.tbz2→ tar -xjf
#      * .tar.xz/.txz  → tar -xJf
#      * .tar.zst/.tzst→ tar --use-compress-program=unzstd
#      * .7z           → 7z
#      * .rar          → unrar
#      * .arj          → arj
#      * .gz, .bz2, .xz, .zst, .lz, .lzo, .lzma
#                    → respective decompression utilities
#      * .deb          → dpkg-deb
#      * .rpm          → rpm2cpio | cpio
#      * .iso          → mount (requires root) – just a notice
#
#  The script is deliberately tolerant: if one archive fails it will
#  report the error and continue with the next file.
#
#  Author:  OpenAI ChatGPT
#  Date:    2025‑09‑02
#=====================================================================

set -euo pipefail

# --------------------------------------------------------------
#  Helper: print error to stderr
# --------------------------------------------------------------
err() { printf '%s\\n' "$*" >&2; }

# --------------------------------------------------------------
#  Helper: check if a command exists
# --------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------
#  Detect format based on 'file' output or extension
# --------------------------------------------------------------
detect_format() {
  local file="$1"
  local type
  type=$(file -b "$file")

  # Normalise a few common patterns
  case "$type" in
  *"ZIP archive data"*)
    echo "zip"
    return
    ;;
  *"7z archive data"*)
    echo "7z"
    return
    ;;
  *"RAR archive data"*)
    echo "rar"
    return
    ;;
  *"ISO image data"*)
    echo "iso"
    return
    ;;
  *"tar archive data"*)
    echo "tar"
    return
    ;;
  *"gzip compressed data"*)
    echo "gz"
    return
    ;;
  *"bzip2 compressed data"*)
    echo "bz2"
    return
    ;;
  *"xz compressed data"*)
    echo "xz"
    return
    ;;
  *"zstd compressed data"*)
    echo "zst"
    return
    ;;
  *"lzip compressed data"*)
    echo "lz"
    return
    ;;
  *"lzop compressed data"*)
    echo "lzo"
    return
    ;;
  *"LZMA compressed data"*)
    echo "lzma"
    return
    ;;
  *"Debian package archive data"*)
    echo "deb"
    return
    ;;
  *"RPM package data"*)
    echo "rpm"
    return
    ;;
  esac

  # Fallback: extension heuristics
  local ext
  ext="${file##*.}"
  case "$ext" in
  zip)
    echo "zip"
    return
    ;;
  7z)
    echo "7z"
    return
    ;;
  rar)
    echo "rar"
    return
    ;;
  iso)
    echo "iso"
    return
    ;;
  tar)
    echo "tar"
    return
    ;;
  gz)
    echo "gz"
    return
    ;;
  bz2)
    echo "bz2"
    return
    ;;
  xz)
    echo "xz"
    return
    ;;
  zst)
    echo "zst"
    return
    ;;
  lz)
    echo "lz"
    return
    ;;
  lzo)
    echo "lzo"
    return
    ;;
  lzma)
    echo "lzma"
    return
    ;;
  deb)
    echo "deb"
    return
    ;;
  rpm)
    echo "rpm"
    return
    ;;
  esac

  # If nothing matched, default to 'unknown'
  echo "unknown"
}

# --------------------------------------------------------------
#  Extract a single archive
# --------------------------------------------------------------
extract_archive() {
  local src="$1"
  local fmt="$2"
  local dest="${src%.*}_extracted"

  if [[ -d "$dest" ]]; then
    err "Destination directory '$dest' already exists – skipping."
    return
  fi

  mkdir -p "$dest"

  echo "=== Extracting: $src  (${fmt})  →  $dest ==="

  case "$fmt" in
  zip)
    if has unzip; then
      unzip -q "$src" -d "$dest"
    else
      err "unzip not installed – cannot extract $src."
    fi
    ;;
  7z)
    if has 7z; then
      7z x -o"$dest" -y "$src" >/dev/null
    else
      err "7z (p7zip) not installed – cannot extract $src."
    fi
    ;;
  rar)
    if has unrar; then
      unrar x -y -o+ "$src" "$dest/"
    else
      err "unrar not installed – cannot extract $src."
    fi
    ;;
  iso)
    err "ISO extraction requires mounting; this script only prints a notice."
    ;;
  tar)
    if has tar; then
      tar -xf "$src" -C "$dest"
    else
      err "tar not installed – cannot extract $src."
    fi
    ;;
  gz)
    if has tar; then
      tar -xzf "$src" -C "$dest"
    elif has gzip; then
      gzip -d -c "$src" >"$dest/${src##*/}.gz"
    else
      err "Neither tar nor gzip available – cannot extract $src."
    fi
    ;;
  bz2)
    if has tar; then
      tar -xjf "$src" -C "$dest"
    elif has bunzip2; then
      bunzip2 -c "$src" >"$dest/${src##*/}.bz2"
    else
      err "Neither tar nor bunzip2 available – cannot extract $src."
    fi
    ;;
  xz)
    if has tar; then
      tar -xJf "$src" -C "$dest"
    elif has xz; then
      xz -d -c "$src" >"$dest/${src##*/}.xz"
    else
      err "Neither tar nor xz available – cannot extract $src."
    fi
    ;;
  zst)
    if has tar; then
      tar --use-compress-program=unzstd -xvf "$src" -C "$dest"
    elif has unzstd; then
      unzstd -c "$src" >"$dest/${src##*/}.zst"
    else
      err "Neither tar nor unzstd available – cannot extract $src."
    fi
    ;;
  lz)
    if has lzip; then
      lzip -d -c "$src" >"$dest/${src##*/}.lz"
    else
      err "lzip not installed – cannot extract $src."
    fi
    ;;
  lzo)
    if has lzop; then
      lzop -d -c "$src" >"$dest/${src##*/}.lzo"
    else
      err "lzop not installed – cannot extract $src."
    fi
    ;;
  lzma)
    if has lzma; then
      lzma -d -c "$src" >"$dest/${src##*/}.lzma"
    else
      err "lzma not installed – cannot extract $src."
    fi
    ;;
  deb)
    if has dpkg-deb; then
      dpkg-deb -x "$src" "$dest"
    else
      err "dpkg-deb not available – cannot extract $src."
    fi
    ;;
  rpm)
    if has rpm2cpio && has cpio; then
      rpm2cpio "$src" | cpio -idmv -D "$dest"
    else
      err "rpm2cpio or cpio not available – cannot extract $src."
    fi
    ;;
  unknown)
    err "Could not identify the format of $src – skipping."
    ;;
  *)
    err "Unsupported format ($fmt) for $src – skipping."
    ;;
  esac

  echo "=== Done extracting $src ==="
}

# --------------------------------------------------------------
#  Main loop – iterate over all arguments
# --------------------------------------------------------------
main() {
  if [[ $# -eq 0 ]]; then
    err "No files supplied."
    exit 1
  fi

  for file in "$@"; do
    if [[ ! -f $file ]]; then
      err "File not found: $file"
      continue
    fi

    fmt=$(detect_format "$file")

    if [[ $fmt == "unknown" ]]; then
      err "❌  Unsupported or undetectable format for '$file'."
      continue
    fi

    # If a required tool is missing, warn once per format
    case "$fmt" in
    zip) [[ ! $(has unzip) ]] && err "unzip missing (required for ZIP)" ;;
    7z) [[ ! $(has 7z) ]] && err "7z (p7zip) missing (required for 7z)" ;;
    rar) [[ ! $(has unrar) ]] && err "unrar missing (required for RAR)" ;;
    7z | rar) [[ ! $(has 7z) || ! $(has unrar) ]] && err "One or more 7z/rar tools missing." ;;
    tar) [[ ! $(has tar) ]] && err "tar missing (required for tar, gzip, bzip2, xz)" ;;
    gz | bz2 | xz | zst | lz | lzo | lzma) [[ ! $(has tar) ]] && err "tar missing – some compressed files cannot be extracted" ;;
    deb) [[ ! $(has dpkg-deb) ]] && err "dpkg-deb missing (required for .deb)" ;;
    rpm) [[ ! $(has rpm2cpio) || ! $(has cpio) ]] && err "rpm2cpio/ cpio missing (required for .rpm)" ;;
    *) : ;;
    esac

    extract_archive "$file" "$fmt" || err "Extraction of '$file' failed – continuing with next file."
    echo
  done
}

# --------------------------------------------------------------
#  Kick off
# --------------------------------------------------------------
main "$@"
