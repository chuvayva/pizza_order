#!/usr/bin/env bash
#
# Restore deployment state that another RUN — possibly of another WORKFLOW —
# left behind. Artifacts belong to a run, not to a workflow, so the lookup goes
# through the repo-wide artifacts API filtered by artifact name + branch:
#
#   .github/scripts/fetch_deploy_state.sh <artifact-name> [--required]
#
# Needs GH_TOKEN (permissions: actions: read), GH_REPO and BRANCH in the env.
# Writes tmp/deploy_state.json when a state artifact is found.
#
set -euo pipefail

NAME="${1:?artifact name required}"
MODE="${2:-optional}"
: "${GH_REPO:?GH_REPO is required}"
: "${BRANCH:?BRANCH is required}"

mkdir -p tmp

run_id="$(
  gh api --paginate "repos/$GH_REPO/actions/artifacts?name=$NAME&per_page=100" \
    --jq '.artifacts[]
          | select(.expired == false)
          | select(.workflow_run.head_branch == env.BRANCH)
          | [.created_at, (.workflow_run.id | tostring), .workflow_run.head_sha[0:7]]
          | @tsv' \
  | sort -r | head -n1 | cut -f2
)"

if [ -z "$run_id" ]; then
  if [ "$MODE" = "--required" ]; then
    echo "::error::No '$NAME' artifact found for branch '$BRANCH' — phase 1 has not run (or its artifact expired). Run the phase 1 workflow first." >&2
    exit 1
  fi
  echo "No '$NAME' artifact for branch '$BRANCH' — starting from scratch"
  exit 0
fi

gh run download "$run_id" --name "$NAME" --dir tmp/previous-state
cp tmp/previous-state/deploy_state.json tmp/deploy_state.json

workflow="$(gh api "repos/$GH_REPO/actions/runs/$run_id" --jq '.name')"
echo "Restored state from run $run_id ($workflow): $(jq -c . tmp/deploy_state.json)"
