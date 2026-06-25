output "artifact_registry_repository" {
  description = "Artifact Registry Docker repository name."
  value       = google_artifact_registry_repository.symchaos_repo.name
}

output "api_service_uri" {
  description = "Cloud Run URI for the SymChaos API service. Internal ingress may prevent direct public access."
  value       = google_cloud_run_v2_service.api.uri
}

output "dashboard_service_uri" {
  description = "Cloud Run URI for the SymChaos dashboard service."
  value       = google_cloud_run_v2_service.dashboard.uri
}

output "api_service_account_email" {
  description = "Runtime service account for the SymChaos API."
  value       = google_service_account.api.email
}

output "dashboard_service_account_email" {
  description = "Runtime service account for the SymChaos dashboard."
  value       = google_service_account.dashboard.email
}
