resource "google_cloud_run_v2_service" "api" {
  name     = "symchaos-api"
  location = var.gcp_region
  ingress  = var.api_ingress

  template {
    service_account = google_service_account.api.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = var.api_max_instances
    }

    containers {
      image = var.api_image

      ports {
        container_port = 8080
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "SYMCHAOS_LLM_CASCADE"
        value = "claude,gpt-4o,mock"
      }

      env {
        name = "SYMCHAOS_OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.openai_key.secret_id
            version = "latest"
          }
        }
      }

      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 12

        http_get {
          path = "/readyz"
          port = 8080
        }
      }

      liveness_probe {
        initial_delay_seconds = 30
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3

        http_get {
          path = "/healthz"
          port = 8080
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }
  }

  labels = {
    app         = "symchaos"
    component   = "api"
    environment = var.environment
  }

  depends_on = [
    google_secret_manager_secret_iam_member.api_openai_key_access,
    google_artifact_registry_repository.symchaos_repo
  ]
}

resource "google_cloud_run_v2_service" "dashboard" {
  name     = "symchaos-dashboard"
  location = var.gcp_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.dashboard.email

    scaling {
      min_instance_count = var.dashboard_min_instances
      max_instance_count = var.dashboard_max_instances
    }

    containers {
      image = var.dashboard_image

      ports {
        container_port = 3000
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "SYMCHAOS_API_URL"
        value = google_cloud_run_v2_service.api.uri
      }

      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 12

        http_get {
          path = "/readyz"
          port = 3000
        }
      }

      liveness_probe {
        initial_delay_seconds = 30
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3

        http_get {
          path = "/healthz"
          port = 3000
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }
  }

  labels = {
    app         = "symchaos"
    component   = "dashboard"
    environment = var.environment
  }
}

resource "google_cloud_run_v2_service_iam_member" "dashboard_public_invoker" {
  count    = var.public_dashboard ? 1 : 0
  name     = google_cloud_run_v2_service.dashboard.name
  location = google_cloud_run_v2_service.dashboard.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
