#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${1:-${PROJECT_ID:-}}"
REGION="${2:-${REGION:-us-central1}}"
REPOSITORY="${REPOSITORY:-symchaos-repo}"
TF_DIR="${TF_DIR:-infra/gcp}"
API_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/api:latest"
DASHBOARD_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/dashboard:latest"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Usage: $0 <PROJECT_ID> [REGION]"
  echo "Example: $0 my-gcp-project us-central1"
  exit 1
fi

if [[ ! -d "${TF_DIR}" ]]; then
  echo "Terraform directory not found: ${TF_DIR}"
  exit 1
fi

if [[ ! -f apps/api/Dockerfile ]]; then
  echo "Missing apps/api/Dockerfile"
  exit 1
fi

if [[ ! -f apps/dashboard/Dockerfile ]]; then
  echo "Missing apps/dashboard/Dockerfile"
  exit 1
fi

if [[ -z "${TF_VAR_openai_api_key_secret_value:-}" ]]; then
  echo "TF_VAR_openai_api_key_secret_value must be set before deployment."
  echo "Example: export TF_VAR_openai_api_key_secret_value='sk-...'"
  exit 1
fi

echo "[deploy] Project: ${PROJECT_ID}"
echo "[deploy] Region: ${REGION}"
echo "[deploy] Repository: ${REPOSITORY}"
echo "[deploy] API image: ${API_IMAGE}"
echo "[deploy] Dashboard image: ${DASHBOARD_IMAGE}"

echo "[deploy] Setting gcloud project..."
gcloud config set project "${PROJECT_ID}"

echo "[deploy] Enabling required GCP services..."
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  secretmanager.googleapis.com \
  monitoring.googleapis.com \
  cloudresourcemanager.googleapis.com

echo "[deploy] Terraform init..."
terraform -chdir="${TF_DIR}" init

echo "[deploy] Phase 1: create Artifact Registry only..."
terraform -chdir="${TF_DIR}" apply \
  -target=google_artifact_registry_repository.symchaos_repo \
  -var="gcp_project_id=${PROJECT_ID}" \
  -var="gcp_region=${REGION}" \
  -var="api_image=${API_IMAGE}" \
  -var="dashboard_image=${DASHBOARD_IMAGE}"

echo "[deploy] Authenticating Docker to Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

echo "[deploy] Building and pushing API image..."
docker build -t "${API_IMAGE}" -f apps/api/Dockerfile .
docker push "${API_IMAGE}"

echo "[deploy] Building and pushing dashboard image..."
docker build -t "${DASHBOARD_IMAGE}" -f apps/dashboard/Dockerfile .
docker push "${DASHBOARD_IMAGE}"

echo "[deploy] Phase 3: apply full infrastructure..."
terraform -chdir="${TF_DIR}" apply \
  -var="gcp_project_id=${PROJECT_ID}" \
  -var="gcp_region=${REGION}" \
  -var="api_image=${API_IMAGE}" \
  -var="dashboard_image=${DASHBOARD_IMAGE}"

echo "[deploy] SymChaos GCP deployment complete."
