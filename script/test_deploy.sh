#!/usr/bin/env bash
#
# Two-phased deployment harness (no real services — every step just sleeps).
#
#   script/test_deploy.sh --until 3     # phase 1: run steps 1..3
#   script/test_deploy.sh --finalize    # phase 2: run whatever is left
#   script/test_deploy.sh               # run everything in one go
#   script/test_deploy.sh --status      # print state, run nothing
#
# State of finished steps is persisted as JSON after every step:
#   { "1": "applied", "2": "applied", "3": "applied" }
#
set -euo pipefail

STEP_NAMES=(
  "build_assets"
  "run_migrations"
  "deploy_web"
  "switch_traffic"
  "smoke_tests"
)
TOTAL=${#STEP_NAMES[@]}
SLEEP_SECONDS="${DEPLOY_STEP_SLEEP:-2}"
STATE_FILE="${DEPLOY_STATE_FILE:-tmp/deploy_state.json}"

mode="full"
until_step=""

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

die() { echo "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --until)      [ "$mode" = "full" ] || die "--until and --finalize are mutually exclusive"
                  mode="until"; until_step="${2:-}"; shift 2 ;;
    --until=*)    [ "$mode" = "full" ] || die "--until and --finalize are mutually exclusive"
                  mode="until"; until_step="${1#*=}"; shift ;;
    --finalize)   [ "$mode" = "full" ] || die "--until and --finalize are mutually exclusive"
                  mode="finalize"; shift ;;
    --status)     mode="status"; shift ;;
    --state)      STATE_FILE="${2:?--state needs a path}"; shift 2 ;;
    --state=*)    STATE_FILE="${1#*=}"; shift ;;
    -h|--help)    usage 0 ;;
    *)            echo "unknown argument: $1" >&2; usage 1 ;;
  esac
done

if [ "$mode" = "until" ]; then
  case "$until_step" in
    ''|*[!0-9]*) die "--until expects a step number 1..$TOTAL, got '${until_step}'" ;;
  esac
  [ "$until_step" -ge 1 ] && [ "$until_step" -le "$TOTAL" ] \
    || die "--until expects a step number 1..$TOTAL, got '${until_step}'"
fi

command -v jq >/dev/null || die "jq is required"

mkdir -p "$(dirname "$STATE_FILE")"
[ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"
jq empty "$STATE_FILE" 2>/dev/null || die "$STATE_FILE is not valid JSON"

applied() { [ "$(jq -r --arg k "$1" '.[$k] // "pending"' "$STATE_FILE")" = "applied" ]; }

mark_applied() {
  local tmp; tmp="$(mktemp)"
  jq --arg k "$1" '.[$k] = "applied"' "$STATE_FILE" > "$tmp"
  mv "$tmp" "$STATE_FILE"
}

print_state() {
  echo "state ($STATE_FILE):"
  local i
  for i in $(seq 1 "$TOTAL"); do
    printf '  %s. %-16s %s\n' "$i" "${STEP_NAMES[$((i - 1))]}" \
      "$(jq -r --arg k "$i" '.[$k] // "pending"' "$STATE_FILE")"
  done
  echo "  raw: $(jq -c . "$STATE_FILE")"
}

if [ "$mode" = "status" ]; then
  print_state
  exit 0
fi

case "$mode" in
  until)    target="$until_step"; phase="phase 1 (--until $until_step)" ;;
  finalize) target="$TOTAL";      phase="phase 2 (--finalize)" ;;
  full)     target="$TOTAL";      phase="single phase (full)" ;;
esac

echo "==> deploy $phase — steps 1..$target of $TOTAL"
print_state
echo

ran=0
for i in $(seq 1 "$target"); do
  name="${STEP_NAMES[$((i - 1))]}"
  if applied "$i"; then
    echo "--> step $i/$TOTAL $name: already applied, skipping"
    continue
  fi
  echo "--> step $i/$TOTAL $name: running (${SLEEP_SECONDS}s)"
  sleep "$SLEEP_SECONDS"
  mark_applied "$i"
  ran=$((ran + 1))
  echo "    step $i/$TOTAL $name: applied"
done

echo
echo "==> $phase done — $ran step(s) executed this run"
print_state

remaining=""
for i in $(seq 1 "$TOTAL"); do applied "$i" || remaining="$remaining $i"; done
if [ -n "$remaining" ]; then
  echo "==> pending steps:$remaining — run with --finalize to complete"
else
  echo "==> deployment complete"
fi
