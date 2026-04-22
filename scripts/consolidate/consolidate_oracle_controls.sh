#!/usr/bin/env bash
#
# consolidate_oracle_controls.sh
#
# Consolidates a directory of legacy one-file-per-control InSpec NIST
# controls (c_*.rb) into a single trusted.rb that mirrors the
# oracle_inspec role's canonical connection block:
#
#   sql = oracledb_session(
#     user:     input('usernm'),
#     password: input('passwd'),
#     host:     input('hostnm'),
#     port:     input('port', value: 1521),
#     service:  input('servicenm')
#   )
#
#   def oracle_int(value)
#     value.to_s.strip.to_i
#   end
#
# The legacy per-file `sql = oracledb_session(...)` / `oracle_session(...)`
# one-liners are stripped; each control body is appended in filename
# order with a "# --- c_X_YY.rb ---" divider.
#
# Usage:
#   Drop this script into a directory that contains c_*.rb files and run it.
#
#     cd ORACLE19_ruby/
#     ./consolidate_oracle_controls.sh
#
# Options:
#   -o FILE   Output file (default: trusted.rb)
#   -p GLOB   Input glob (default: c_*.rb)
#   -f        Force overwrite if the output file already exists
#   -n        Dry run — print a preview, do not write
#   -h        Help

set -euo pipefail

OUTPUT="trusted.rb"
PATTERN="c_*.rb"
FORCE=0
DRYRUN=0
# Strips legacy oracledb_session or oracle_session declarations.
SESSION_RE='^[[:space:]]*sql[[:space:]]*=.*(oracledb_session|oracle_session)'

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
# Consolidated Oracle NIST controls
HEADER_EOF
{
  echo "# Generated from ${#FILES[@]} legacy c_*.rb files by $(basename "$0")"
  echo "# Source directory: $(pwd)"
  echo "# Generated on: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$TMP"

# Canonical Oracle connection block — mirrors oracle_inspec role's
# ssc-cis-oracle<ver>-*/controls/trusted.rb.
cat >> "$TMP" <<'CONN_EOF'

# Establish connection to Oracle using the native oracledb_session resource.
# Password is passed via input and handled securely by InSpec.
#
# NOTE: Oracle sqlplus may return values with leading whitespace/tabs.
# All numeric comparisons use oracle_int (or .to_s.strip) to handle this.
sql = oracledb_session(
  user: input('usernm'),
  password: input('passwd'),
  host: input('hostnm'),
  port: input('port', value: 1521),
  service: input('servicenm')
)

# Helper: safely compare Oracle numeric output (handles whitespace)
def oracle_int(value)
  value.to_s.strip.to_i
end

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
