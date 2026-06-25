# SymChaos GCP Terraform Module

This module deploys the SymChaos portfolio architecture on Google Cloud using Cloud Run V2, Artifact Registry, Secret Manager, Cloud Monitoring, and least-privilege runtime service accounts.

## Architecture posture

- API and dashboard run as separate Cloud Run services.
- API uses a dedicated service account with Secret Manager access to the OpenAI key only.
- Dashboard uses a separate service account and can be exposed publicly.
- API ingress defaults to `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` for stronger enterprise posture.
- Artifact Registry is declared explicitly as `symchaos-repo`.
- Monitoring includes an API 4xx alert. Veto-specific alerting should be added after the API exports `symchaos_veto_total` as a custom metric.

## Required inputs

```hcl
gcp_project_id                  = "your-gcp-project"
gcp_region                      = "us-central1"
api_image                       = "us-central1-docker.pkg.dev/your-gcp-project/symchaos-repo/api:latest"
dashboard_image                 = "us-central1-docker.pkg.dev/your-gcp-project/symchaos-repo/dashboard:latest"
openai_api_key_secret_value     = "set-with-TF_VAR-or-secure-ci-secret"
```

## Recommended secret handling

Prefer setting the key outside committed files:

```bash
export TF_VAR_openai_api_key_secret_value="..."
terraform init
terraform plan
terraform apply
```

Do not commit `.tfvars` files containing live API keys.

## Fresh-project cold start

A new GCP project has a bootstrapping dependency: Cloud Run needs images to exist before services can be created, but the image repository is also created by Terraform. Use the targeted two-phase flow below.

### Automated path

From the repository root:

```bash
export TF_VAR_openai_api_key_secret_value="..."
make deploy-gcp-coldstart PROJECT_ID="your-gcp-project" REGION="us-central1"
```

The script will:

1. Enable required GCP services.
2. Run `terraform init`.
3. Apply only `google_artifact_registry_repository.symchaos_repo`.
4. Authenticate Docker to Artifact Registry.
5. Build and push API and dashboard images.
6. Apply the full Terraform stack.

### Manual path

```bash
cd infra/gcp
terraform init
terraform apply -target=google_artifact_registry_repository.symchaos_repo
```

Then from the repository root:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev

docker build -t us-central1-docker.pkg.dev/[PROJECT_ID]/symchaos-repo/api:latest -f apps/api/Dockerfile .
docker push us-central1-docker.pkg.dev/[PROJECT_ID]/symchaos-repo/api:latest

docker build -t us-central1-docker.pkg.dev/[PROJECT_ID]/symchaos-repo/dashboard:latest -f apps/dashboard/Dockerfile .
docker push us-central1-docker.pkg.dev/[PROJECT_ID]/symchaos-repo/dashboard:latest
```

Finally:

```bash
cd infra/gcp
terraform apply
```
