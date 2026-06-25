variable "gcp_project_id" {
  description = "GCP project ID for the SymChaos deployment."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "api_image" {
  description = "Container image URI for the SymChaos API service."
  type        = string
}

variable "dashboard_image" {
  description = "Container image URI for the SymChaos dashboard service."
  type        = string
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "portfolio"
}

variable "openai_api_key_secret_value" {
  description = "Initial OpenAI API key value to place in Secret Manager. Prefer setting through TF_VAR_openai_api_key_secret_value or a secure CI secret."
  type        = string
  sensitive   = true
}

variable "api_min_instances" {
  description = "Minimum Cloud Run API instances."
  type        = number
  default     = 0
}

variable "api_max_instances" {
  description = "Maximum Cloud Run API instances."
  type        = number
  default     = 10
}

variable "dashboard_min_instances" {
  description = "Minimum Cloud Run dashboard instances."
  type        = number
  default     = 0
}

variable "dashboard_max_instances" {
  description = "Maximum Cloud Run dashboard instances."
  type        = number
  default     = 5
}

variable "public_dashboard" {
  description = "Whether to allow unauthenticated public access to the dashboard."
  type        = bool
  default     = true
}

variable "api_ingress" {
  description = "Cloud Run ingress mode for the API. Use INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER for stronger enterprise posture."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    ], var.api_ingress)
    error_message = "api_ingress must be a valid Cloud Run V2 ingress enum."
  }
}
