#!/usr/bin/env bash
#=============================================================
#  zipinstall.sh  –  Installs all compression/decompression tools
#=============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/install-compression-tools.sh" "$@"

