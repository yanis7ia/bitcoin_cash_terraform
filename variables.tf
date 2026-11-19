variable "project_id" {
  description = "Unique Google Cloud project ID"
  type        = string
}

variable "project_name" {
  description = "Google Cloud project name"
  type        = string
}

variable "billing_account" {
  description = "Google Cloud billing account ID"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "US"
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format"
  type        = string
}