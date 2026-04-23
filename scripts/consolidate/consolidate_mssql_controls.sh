#!/usr/bin/env bash
#
# consolidate_mssql_controls.sh
#
# Consolidates a directory of legacy one-file-per-control InSpec NIST
# controls (c_*.rb) into a single trusted.rb that mirrors the
# mssql_inspec role's canonical connection block:
#
#   _usernm = input('usernm', value: nil)
#   _passwd = input('passwd', value: nil)
#   _hostnm = input('hostnm', value: 'localhost')
#   _port   = input('port',   value: 1433)
#   _servicenm = input('servicenm', value: '')
#
#   use_windows_auth = _usernm.nil? || _usernm.to_s.strip.empty?
#   sql = if use_windows_auth
#           mssql_session(host: _hostnm, port: _port, instance: _servicenm)
#         else
#           mssql_session(user: _usernm, password: _passwd,
#                         host: _hostnm, port: _port, instance: _servicenm)
#         end
#
# The legacy per-file `sql = mssql_session(...)` one-liners are
# stripped; each control body is appended in filename order with a
# "# --- c_X_YY.rb ---" divider.
#
# Usage:
#   Drop this script into a directory that contains c_*.rb files and run it.
#
#     cd MSSQL2019_ruby/
#     ./consolidate_mssql_controls.sh
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
# Strips both the bare legacy one-liner and any multi-line `sql = mssql_session(` opener.
SESSION_RE='^[[:space:]]*sql[[:space:]]*=.*mssql_session'

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

# The canonical MSSQL connection block — mirrors roles'
# inspec_cis_database/.../ssc-cis-mssql<ver>-*/controls/trusted.rb
cat > "$TMP" <<'HEADER_EOF'
# Consolidated MSSQL NIST controls
HEADER_EOF
{
  echo "# Generated from ${#FILES[@]} legacy c_*.rb files by $(basename "$0")"
  echo "# Source directory: $(pwd)"
  echo "# Generated on: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$TMP"

cat >> "$TMP" <<'CONN_EOF'

# Establish connection to MSSQL
# Supports both SQL Server Authentication and Windows Authentication
# - Windows Auth: When usernm is empty/nil, omit credentials to use Windows identity
# - SQL Auth: When usernm is provided, use SQL Server Authentication
_usernm = input('usernm', value: nil)
_passwd = input('passwd', value: nil)
_hostnm = input('hostnm', value: 'localhost')
_port = input('port', value: 1433)
_servicenm = input('servicenm', value: '')

# Determine authentication mode - empty/nil credentials trigger Windows Auth
use_windows_auth = _usernm.nil? || _usernm.to_s.strip.empty?

sql = if use_windows_auth
  # Windows Authentication - omit user/password to use current Windows identity
  mssql_session(
    host: _hostnm,
    port: _port,
    instance: _servicenm
  )
else
  # SQL Server Authentication - use provided credentials
  mssql_session(
    user: _usernm,
    password: _passwd,
    host: _hostnm,
    port: _port,
    instance: _servicenm
  )
end

CONN_EOF

# Append each legacy control with its session line stripped.
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
