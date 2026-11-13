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

has_api=false
has_dashboard=false
if [[ -f apps/api/main.py || -f apps/api/app/main.py ]]; then has_api=true; fi
if [[ -f apps/dashboard/package.json ]]; then has_dashboard=true; fi

# The repository currently contains infrastructure and hardware only.
# Never report a successful service start when no application exists.
if [[ "$has_api" == false && "$has_dashboard" == false ]]; then
  echo "[dev] scaffold only: no API or dashboard entrypoint is checked in." >&2
  echo "[dev] Run 'make smoke' to verify the available infra/hardware scaffold." >&2
  exit 2
fi

echo "[dev] Starting available SymChaos local services..."
if [[ "$has_api" == true ]]; then
  run_api &
  pids+=("$!")
fi
if [[ "$has_dashboard" == true ]]; then
  run_dashboard &
  pids+=("$!")
fi

# Stop the other service when one exits, even on startup failure.
wait -n "${pids[@]}"
