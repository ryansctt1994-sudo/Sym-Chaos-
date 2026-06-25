resource "google_service_account" "api" {
  account_id   = "symchaos-api"
  display_name = "SymChaos API Cloud Run service account"
  description  = "Least-privilege runtime identity for the SymChaos API."
}

resource "google_service_account" "dashboard" {
  account_id   = "symchaos-dashboard"
  display_name = "SymChaos dashboard Cloud Run service account"
  description  = "Runtime identity for the public dashboard."
}

resource "google_secret_manager_secret_iam_member" "api_openai_key_access" {
  secret_id = google_secret_manager_secret.openai_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api.email}"
}

resource "google_artifact_registry_repository_iam_member" "api_artifact_reader" {
  location   = google_artifact_registry_repository.symchaos_repo.location
  repository = google_artifact_registry_repository.symchaos_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.api.email}"
}

resource "google_artifact_registry_repository_iam_member" "dashboard_artifact_reader" {
  location   = google_artifact_registry_repository.symchaos_repo.location
  repository = google_artifact_registry_repository.symchaos_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.dashboard.email}"
}
