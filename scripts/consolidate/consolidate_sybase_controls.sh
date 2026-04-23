#!/usr/bin/env bash
#
# consolidate_sybase_controls.sh
#
# Consolidates a directory of legacy one-file-per-control InSpec NIST
# controls (c_*.rb) into a single trusted.rb that mirrors the
# sybase_inspec role's canonical connection block:
#
#   sybase_opts = {
#     username: input('usernm'),
#     password: input('passwd'),
#     server:   input('servicenm'),
#     database: input('database', value: 'master')
#   }
#
#   # Optional overrides (sybase_home, isql_bin, interfaces_file, ssl_enabled)
#   # are injected into sybase_opts only when the input is non-empty.
#
#   sql = sybase_session_local(sybase_opts)
#
# The legacy per-file `sql = sybase_session(...)` / `sql = command(...)`
# one-liners are stripped; each control body is appended in filename
# order with a "# --- c_X_YY.rb ---" divider.
#
# Usage:
#   Drop this script into a directory that contains c_*.rb files and run it.
#
#     cd SYBASE16_ruby/
#     ./consolidate_sybase_controls.sh
#
# Options:
#   -o FILE   Output file (default: trusted.rb)
#   -p GLOB   Input glob (default: c_*.rb)
#   -f        Force overwrite if the output file already exists
#   -n        Dry run — print a preview, do not write
#   -h        Help
#
# Note:
#   The canonical block uses `sybase_session_local`, a custom resource
#   shipped with the sybase_inspec role. The consolidated output is
#   intended to run under that role's InSpec environment.

set -euo pipefail

OUTPUT="trusted.rb"
PATTERN="c_*.rb"
FORCE=0
DRYRUN=0
# Strip legacy direct sybase_session or command-based bootstrap lines.
SESSION_RE='^[[:space:]]*sql[[:space:]]*=.*(sybase_session|command)'

usage() { sed -n '2,/^$/p' "$0" | sed 's/^#\s\?//'; }

while getopts ":o:p:fnh" opt; do
  case $opt in
    o) OUTPUT=$OPTARG ;;
    p) PATTERN=$OPTARG ;;
    f) FORCE=1 ;;
    n) DRYRUN=1 ;;
    h) usage; exit 0 ;;
    \?) echo "error: unknown flag -$OPTARG" >&2; exit 2 ;;
    :)  echo "error: -$OPTARG requires an argument" >&2; exit 2 ;;
  esac
done

shopt -s nullglob
# shellcheck disable=SC2206
FILES=( $PATTERN )
shopt -u nullglob

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "error: no files matching '$PATTERN' in $(pwd)" >&2
  exit 1
fi

IFS=$'\n' FILES=($(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort))
unset IFS

if [[ -e $OUTPUT && $FORCE -eq 0 && $DRYRUN -eq 0 ]]; then
  echo "error: $OUTPUT already exists — pass -f to overwrite" >&2
  exit 1
fi

echo "Consolidating ${#FILES[@]} file(s) -> $OUTPUT"
[[ $DRYRUN -eq 1 ]] && echo "(dry run — preview only, nothing will be written)"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" <<'HEADER_EOF'
# Consolidated Sybase NIST controls
HEADER_EOF
{
  echo "# Generated from ${#FILES[@]} legacy c_*.rb files by $(basename "$0")"
  echo "# Source directory: $(pwd)"
  echo "# Generated on: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$TMP"

# Canonical Sybase connection block — mirrors sybase_inspec role's
# ssc-cis-sybase<ver>-*/controls/trusted.rb.
cat >> "$TMP" <<'CONN_EOF'

# Establish connection to Sybase ASE via sybase_session_local (custom
# resource shipped with the sybase_inspec role).
# Password is passed via input and handled securely by InSpec.
sybase_opts = {
  username: input('usernm'),
  password: input('passwd'),
  server: input('servicenm'),
  database: input('database', value: 'master')
}

# Optional overrides — only injected when the input is non-empty
sybase_home_val = input('sybase_home', value: '')
isql_bin_val = input('isql_bin', value: '')
interfaces_file_val = input('interfaces_file', value: '')
sybase_opts[:sybase_home] = sybase_home_val unless sybase_home_val.to_s.empty?
sybase_opts[:bin] = isql_bin_val unless isql_bin_val.to_s.empty?
sybase_opts[:interfaces_file] = interfaces_file_val unless interfaces_file_val.to_s.empty?

ssl_enabled_val = input('ssl_enabled', value: false)
sybase_opts[:ssl_enabled] = ssl_enabled_val if ssl_enabled_val

sql = sybase_session_local(sybase_opts)

CONN_EOF

{
  for f in "${FILES[@]}"; do
    printf '# --- %s ---\n' "$(basename "$f")"
    grep -v -E "$SESSION_RE" "$f"
    printf '\n'
  done
} >> "$TMP"

if [[ $DRYRUN -eq 1 ]]; then
  head -60 "$TMP"
  total=$(wc -l < "$TMP" | tr -d ' ')
  echo "..."
  echo "(dry run — $total lines generated, not written)"
else
  mv "$TMP" "$OUTPUT"
  trap - EXIT
  echo "Wrote $OUTPUT ($(wc -l < "$OUTPUT" | tr -d ' ') lines, from ${#FILES[@]} source files)"
fi
