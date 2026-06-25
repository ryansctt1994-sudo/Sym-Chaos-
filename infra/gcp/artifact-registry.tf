resource "google_artifact_registry_repository" "symchaos_repo" {
  location      = var.gcp_region
  repository_id = "symchaos-repo"
  description   = "Docker repository for SymChaos API and dashboard images."
  format        = "DOCKER"

  labels = {
    app         = "symchaos"
    environment = var.environment
  }
}
