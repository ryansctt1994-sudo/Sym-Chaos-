resource "google_monitoring_alert_policy" "api_error_alert" {
  display_name = "SymChaos API 4xx Error Alert"
  combiner     = "OR"
  enabled      = true

  documentation {
    content   = "Cloud Run API is returning elevated 4xx responses. This is an API error alert, not a veto-event alert. Export symchaos_veto_total as a custom metric before adding veto-specific alerting."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Cloud Run API 4xx responses above threshold"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"cloud_run_revision\"",
        "resource.labels.service_name = \"${google_cloud_run_v2_service.api.name}\"",
        "metric.type = \"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class = \"4xx\""
      ])

      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 25

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.service_name"]
      }

      trigger {
        count = 1
      }
    }
  }

  user_labels = {
    app         = "symchaos"
    component   = "api"
    environment = var.environment
  }
}

# Future veto-specific alert once the API exports a custom metric:
#
# resource "google_monitoring_alert_policy" "veto_event_alert" {
#   display_name = "SymChaos Veto Event Alert"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "symchaos_veto_total above threshold"
#
#     condition_threshold {
#       filter          = "metric.type = \"custom.googleapis.com/symchaos_veto_total\""
#       duration        = "60s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0
#     }
#   }
# }
