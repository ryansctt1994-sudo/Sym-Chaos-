resource "google_secret_manager_secret" "openai_key" {
  secret_id = "symchaos-openai-api-key"

  replication {
    auto {}
  }

  labels = {
    app         = "symchaos"
    environment = var.environment
  }
}

resource "google_secret_manager_secret_version" "openai_key" {
  secret      = google_secret_manager_secret.openai_key.id
  secret_data = var.openai_api_key_secret_value
}
