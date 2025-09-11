#!/usr/bin/env bash

# =============================================================================
# VPS Setup Utilities
# =============================================================================
# Common functions used across multiple setup scripts
# Source this file: source "$(dirname "$0")/utils.sh"
# =============================================================================

# Adds or updates a single alias in the given file
update_alias() {
    local name="$1"
    local value="$2"
    local file="$3"

    # Create file if it doesn't exist
    touch "$file"

    # If the alias already exists, replace its definition
    if grep -qE "^alias ${name}=" "$file" 2>/dev/null; then
        sed -i "s|^alias ${name}=.*|alias ${name}='${value}'|" "$file"
    else
        # Otherwise append it
        echo "alias ${name}='${value}'" >> "$file"
    fi
}

# Adds a block of shell functions using heredoc with marker system
add_functions_block() {
    local file="$1"
    local marker="$2"

    touch "$file"

    # Only add if marker doesn't exist
    if ! grep -q "$marker" "$file" 2>/dev/null; then
        if [[ "$marker" == "AWK_HELPERS" ]]; then
            cat >> "$file" << EOF

# $marker
function awkn {
  cmd="awk '{print \\\$$1}'"
  eval "\$cmd"
}

function awklast {
  cmd="awk '{print \\\$NF}'"
  eval "\$cmd"
}
EOF
        elif [[ "$marker" == "TIMESTAMP_HELPERS" ]]; then
            cat >> "$file" << EOF

# $marker
## human-friendly ts function
## Examples:
## * some_app | tee "\$(ts a.txt)"
## * touch "\$(ts notes.md)"
## * vim "\$(ts scratch.md)"
ts() { date +%Y-%m-%d_%H-%M-%S | xargs -I{} printf "%s_%s\n" {} "\$1"; }
EOF
        elif [[ "$marker" == "CLIPBOARD_HELPERS" ]]; then
            cat >> "$file" << 'EOF'

# CLIPBOARD_HELPERS
## f2clip - concatenate files to clipboard or file
## Usage:
## * f2clip firstfile.txt /var/tmp/another.json => copies to clipboard
## * f2clip --file outputfile.txt => write to file
##   * Or just f2clip -f abc.txt ....
f2clip() {
  emulate -L zsh
  set -o pipefail

  # Usage message
  local usage="## Usage:
* f2clip firstfile.txt /var/tmp/another.json => copies to clipboard
* f2clip --file outputfile.txt => write to file
    * Or just f2clip -f abc.txt ...."

  # Parse optional --file / -f
  local -a arg_file
  zparseopts -D -E -- {f,-file}:=arg_file || return 1

  # If no args given, print usage and return
  if (( $# == 0 )); then
    print -r -- "$usage"
    return 0
  fi

  local output_file
  if (( ${#arg_file[@]} )); then
    output_file=${arg_file[-1]}
  fi

  local tmp total_bytes=0 abs file abs_paths=()
  tmp=$(mktemp) || return 1

  for arg in "$@"; do
    if [[ -d $arg ]]; then
      while IFS= read -r -d '' file; do
        abs="$(cd "$(dirname -- "$file")" && pwd)/$(basename -- "$file")"
        abs_paths+=("$abs")
        total_bytes=$(( total_bytes + $(wc -c <"$file") ))
        printf '=== FILE: %s\n' "$abs" >> "$tmp"
        cat -- "$file" >> "$tmp"
        printf '\n\n' >> "$tmp"
      done < <(find "$arg" -type f -print0)
    elif [[ -f $arg ]]; then
      abs="$(cd "$(dirname -- "$arg")" && pwd)/$(basename -- "$arg")"
      abs_paths+=("$abs")
      total_bytes=$(( total_bytes + $(wc -c <"$arg") ))
      printf '=== FILE: %s\n' "$abs" >> "$tmp"
      cat -- "$arg" >> "$tmp"
      printf '\n\n' >> "$tmp"
    fi
  done

  if [[ -n $output_file ]]; then
    mkdir -p -- "${output_file:h}"
    cat -- "$tmp" >| "$output_file"
    print -r -- "Wrote ${#abs_paths[@]} file(s), ~$(( total_bytes / 1024 )) KB total to $output_file."
  else
    cat -- "$tmp" | xclip -selection clipboard
    print -r -- "Copied ${#abs_paths[@]} file(s), ~$(( total_bytes / 1024 )) KB total to clipboard."
  fi

  rm -f -- "$tmp"
}
alias fclip='f2clip'
EOF
        fi
    fi
}

# Check if running with correct privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ Error: This script must be run with sudo" >&2
        echo "Usage: sudo ./$0" >&2
        exit 1
    fi
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "❌ Error: This script should NOT be run with sudo" >&2
        echo "Usage: ./$0 (as regular user)" >&2
        exit 1
    fi
}

# Print section headers
print_section() {
    local title="$1"
    echo ""
    echo "# ---- $title ----"
}

# Log with timestamp (optional utility)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}