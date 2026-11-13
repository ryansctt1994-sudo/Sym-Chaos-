#!/usr/bin/env bash
# Safe, offline scaffold test: no Terraform apply, cloud account or container build.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

bash -n scripts/dev.sh scripts/deploy-gcp-coldstart.sh
test -d infra/gcp || { echo "FAIL: missing Terraform scaffold" >&2; exit 1; }
test -f hardware/src/zorel_veto_axi.v || { echo "FAIL: missing Verilog source" >&2; exit 1; }
test -f README.md || { echo "FAIL: missing README" >&2; exit 1; }

# On a scaffold-only checkout, dev must refuse instead of claiming success.
if [[ ! -f apps/api/main.py && ! -f apps/api/app/main.py && ! -f apps/dashboard/package.json ]]; then
  set +e
  output="$(bash scripts/dev.sh 2>&1)"
  status=$?
  set -e
  if [[ "$status" -ne 2 || "$output" != *"scaffold only"* ]]; then
    printf 'FAIL: expected no-op startup refusal (exit 2); got %s: %s\n' "$status" "$output" >&2
    exit 1
  fi
fi
echo "PASS: offline SymChaos scaffold smoke checks"
