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
