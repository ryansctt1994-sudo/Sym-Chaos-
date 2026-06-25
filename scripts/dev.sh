#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

pids=()

cleanup() {
  for pid in "${pids[@]:-}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done
}
trap cleanup EXIT INT TERM

run_api() {
  if [[ -f apps/api/main.py ]]; then
    uvicorn apps.api.main:app --reload --host 0.0.0.0 --port 8080
  elif [[ -f apps/api/app/main.py ]]; then
    uvicorn apps.api.app.main:app --reload --host 0.0.0.0 --port 8080
  else
    echo "[dev] No FastAPI entrypoint found under apps/api. Skipping API."
  fi
}

run_dashboard() {
  if [[ -f apps/dashboard/package.json ]]; then
    cd "$ROOT_DIR/apps/dashboard"
    npm run dev
  else
    echo "[dev] No dashboard package.json found under apps/dashboard. Skipping dashboard."
  fi
}

echo "[dev] Starting SymChaos local services..."
run_api &
pids+=("$!")
run_dashboard &
pids+=("$!")

wait -n "${pids[@]}"
