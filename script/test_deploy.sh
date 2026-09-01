#!/usr/bin/env bash
#
# Two-phased deployment harness with a lifecycle state machine.
# No real services — every step just sleeps.
#
#   script/test_deploy.sh --until 3     # phase 1: apply steps 1..3, stop at the gate
#   script/test_deploy.sh --finalize    # phase 2: apply the rest
#   script/test_deploy.sh               # plain (non-gated) full deploy
#   script/test_deploy.sh --status      # print state, run nothing
#
# Lifecycle, persisted in the state JSON and validated at every entry point:
#
#   (no file) --until--> deploy-phase-1 --gate stop--> gate
#             --finalize-------------------------------^
#                                        deploy-phase-2 --> finished (lifecycle reset)
#   (no file) --plain--> deploy --> finished
#
# This script is the sole writer of `state`: on entry (once it is committed to
# applying) and on exit (the gate stop / completion). Every entry point is
# validated against the state the last run left behind, so a wrong click is
# refused with a message naming the actual situation. Concurrency of two
# simultaneous clicks is NOT the state's job — that is the CI queue.
#
# Test hooks: DEPLOY_STEP_SLEEP (default 2), DEPLOY_FAIL_AT=<n> (crash at step n),
# DEPLOY_COMMIT, DEPLOY_CLICK_TIME (ISO8601 UTC — when this run was requested).
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
FAIL_AT="${DEPLOY_FAIL_AT:-}"
CLICK_TIME="${DEPLOY_CLICK_TIME:-}"
COMMIT="${DEPLOY_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"

mode="full"
until_step=""

die()   { echo "error: $*" >&2; exit 2; }
now()   { date -u +%Y-%m-%dT%H:%M:%SZ; }

# A refusal is exit 1 and names the situation. Exit 2 is a usage error.
refuse() {
  echo "::error::$*" >&2
  echo "REFUSED: $*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --until)    [ "$mode" = "full" ] || die "--until and --finalize are mutually exclusive"
                mode="until"; until_step="${2:-}"; shift 2 ;;
    --until=*)  [ "$mode" = "full" ] || die "--until and --finalize are mutually exclusive"
                mode="until"; until_step="${1#*=}"; shift ;;
    --finalize) [ "$mode" = "full" ] || die "--until and --finalize are mutually exclusive"
                mode="finalize"; shift ;;
    --status)   mode="status"; shift ;;
    --state)    STATE_FILE="${2:?--state needs a path}"; shift 2 ;;
    --state=*)  STATE_FILE="${1#*=}"; shift ;;
    -h|--help)  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          die "unknown argument: $1" ;;
  esac
done

if [ "$mode" = "until" ]; then
  case "$until_step" in ''|*[!0-9]*) die "--until expects 1..$TOTAL, got '${until_step}'" ;; esac
  { [ "$until_step" -ge 1 ] && [ "$until_step" -le "$TOTAL" ]; } \
    || die "--until expects 1..$TOTAL, got '${until_step}'"
fi

command -v jq >/dev/null || die "jq is required"
mkdir -p "$(dirname "$STATE_FILE")"

# ---------------------------------------------------------------- load state
lifecycle="initial"
steps='{}'
gate_step=""
gate_at=""
state_commit=""
reset_reason=""

if [ -f "$STATE_FILE" ] && jq empty "$STATE_FILE" 2>/dev/null; then
  lifecycle="$(jq -r '.state // ""' "$STATE_FILE")"
  state_commit="$(jq -r '.commit // ""' "$STATE_FILE")"
  gate_step="$(jq -r '.gate_step // ""' "$STATE_FILE")"
  gate_at="$(jq -r '.gate_at // ""' "$STATE_FILE")"
  steps="$(jq -c '.steps // {}' "$STATE_FILE")"

  if [ -z "$lifecycle" ]; then
    # Old flat format: {"1":"applied",...} — derive the lifecycle from it.
    steps="$(jq -c 'with_entries(select(.key | test("^[0-9]+$")))' "$STATE_FILE")"
    if [ "$(jq -r --argjson total "$TOTAL" '[range(1; $total + 1) | tostring] | map(. as $k | ($steps[$k] // "pending")) | all(. == "applied")' --argjson steps "$steps" <<<'null')" = "true" ]; then
      lifecycle="finished"
    else
      lifecycle="deploy"
    fi
  fi

  if [ -n "$state_commit" ] && [ "$state_commit" != "$COMMIT" ]; then
    reset_reason="state was recorded for commit $state_commit, this run is $COMMIT"
    lifecycle="initial"; steps='{}'; gate_step=""; gate_at=""
  elif [ "$lifecycle" = "finished" ]; then
    reset_reason="previous deployment finished — starting a new lifecycle"
    lifecycle="initial"; steps='{}'; gate_step=""; gate_at=""
  fi
fi

applied()  { [ "$(jq -r --arg k "$1" '.[$k] // "pending"' <<<"$steps")" = "applied" ]; }
pending_list() {
  local out="" i
  for i in $(seq 1 "$TOTAL"); do applied "$i" || out="$out $i"; done
  printf '%s' "$out"
}

persist() { # persist <lifecycle> [gate_step]
  local new="$1" gs="${2:-$gate_step}" ga="$gate_at" tmp
  [ "$new" = "gate" ] && ga="$(now)"
  tmp="$(mktemp)"
  jq -n \
    --arg state "$new" --arg commit "$COMMIT" --arg updated "$(now)" \
    --arg gate_step "$gs" --arg gate_at "$ga" --argjson steps "$steps" \
    '{state: $state, commit: $commit, updated_at: $updated, steps: $steps}
     + (if $gate_step == "" then {} else {gate_step: ($gate_step | tonumber)} end)
     + (if $gate_at   == "" then {} else {gate_at: $gate_at} end)' > "$tmp"
  mv "$tmp" "$STATE_FILE"
  lifecycle="$new"; gate_step="$gs"; gate_at="$ga"
}

print_state() {
  local i
  echo "state: $lifecycle${gate_step:+ (gate at step $gate_step)}  commit: $COMMIT  file: $STATE_FILE"
  [ -n "$reset_reason" ] && echo "  note: $reset_reason"
  for i in $(seq 1 "$TOTAL"); do
    printf '  %s. %-16s %s\n' "$i" "${STEP_NAMES[$((i - 1))]}" \
      "$(jq -r --arg k "$i" '.[$k] // "pending"' <<<"$steps")"
  done
  echo "  steps: $steps"
}

if [ "$mode" = "status" ]; then print_state; exit 0; fi

# ------------------------------------------------------- validate this click
# Mirrors the QA2 matrix: each cell is runs / resumes / refuses.
case "$mode:$lifecycle" in
  until:initial)           action="run"    ;;
  until:deploy-phase-1)    action="resume" ;;   # crashed phase 1 re-admits itself
  until:gate)              refuse "the deployment is at its gate awaiting finalize — only --finalize may proceed (gate at step $gate_step)" ;;
  until:deploy-phase-2)    refuse "a finalize is executing (or crashed mid-finalize) — finish the finalize before deploying again" ;;
  until:deploy)            refuse "a plain (non-gated) deploy is running or crashed — re-run it to completion first" ;;

  finalize:initial)        refuse "no clean gate stop recorded (the deploy phase hasn't run)" ;;
  finalize:deploy-phase-1) refuse "the deploy phase is running or failed before its gate — re-run the gated deploy first" ;;
  finalize:gate)           action="run"    ;;
  finalize:deploy-phase-2) action="resume" ;;   # resuming a finalize that did not complete
  finalize:deploy)         refuse "this deployment was not gated — there is nothing to finalize" ;;

  full:initial)            action="run"    ;;
  full:deploy)             action="resume" ;;
  full:deploy-phase-1)     refuse "a gated deploy is running or crashed before its gate — re-run the gated deploy" ;;
  full:gate)               refuse "the deployment is at its gate awaiting finalize — finalize first, then redeploy" ;;
  full:deploy-phase-2)     refuse "a finalize is executing (or crashed mid-finalize) — finish it first" ;;

  *) die "unhandled state '$lifecycle' for mode '$mode'" ;;
esac

# Closes the click-before-the-gate race: a finalize requested BEFORE the gate
# was recorded was clicked while phase 1 was still applying, and must not be
# allowed to consume the pause just because it was scheduled late.
if [ "$mode" = "finalize" ] && [ -n "$CLICK_TIME" ] && [ -n "$gate_at" ] \
   && [ "$CLICK_TIME" \< "$gate_at" ]; then
  refuse "this finalize was requested at $CLICK_TIME, before the gate was recorded at $gate_at — it was clicked while the deploy phase was still running; click finalize again"
fi

case "$mode" in
  until)    target="$until_step"; entry="deploy-phase-1"; phase="phase 1 (--until $until_step)" ;;
  finalize) target="$TOTAL";      entry="deploy-phase-2"; phase="phase 2 (--finalize)" ;;
  full)     target="$TOTAL";      entry="deploy";         phase="plain deploy (full)" ;;
esac

echo "==> $phase — steps 1..$target of $TOTAL  [$action, lifecycle: $lifecycle -> $entry]"
print_state
echo

# --------------------------------------------------------------------- apply
persist "$entry"

ran=0
for i in $(seq 1 "$target"); do
  name="${STEP_NAMES[$((i - 1))]}"
  if applied "$i"; then
    echo "--> step $i/$TOTAL $name: already applied, skipping"
    continue
  fi
  echo "--> step $i/$TOTAL $name: running (${SLEEP_SECONDS}s)"
  sleep "$SLEEP_SECONDS"
  if [ -n "$FAIL_AT" ] && [ "$i" = "$FAIL_AT" ]; then
    echo "    step $i/$TOTAL $name: FAILED (DEPLOY_FAIL_AT=$FAIL_AT)" >&2
    persist "$entry"                      # epilogue: state mirrors the crash
    exit 1
  fi
  steps="$(jq -c --arg k "$i" '.[$k] = "applied"' <<<"$steps")"
  persist "$entry"
  ran=$((ran + 1))
  echo "    step $i/$TOTAL $name: applied"
done

# ---------------------------------------------------------------------- exit
if [ "$mode" = "until" ] && [ -n "$(pending_list)" ]; then
  persist "gate" "$until_step"
  echo
  echo "==> $phase done — $ran step(s) executed, stopped at the gate after step $until_step"
  print_state
  echo "==> pending steps:$(pending_list) — run --finalize to complete"
else
  persist "finished"
  echo
  echo "==> $phase done — $ran step(s) executed this run"
  print_state
  echo "==> deployment complete"
fi
