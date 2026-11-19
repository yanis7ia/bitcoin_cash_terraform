output "project_id" {
  value = google_project.bitcoin_cash.project_id
}

output "staging_dataset" {
  value = google_bigquery_dataset.staging.dataset_id
}

output "mart_dataset" {
  value = google_bigquery_dataset.mart.dataset_id
}

output "service_account_email" {
  value = google_service_account.dbt.email
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "dbt_service_account" {
  value = google_service_account.dbt.email
}