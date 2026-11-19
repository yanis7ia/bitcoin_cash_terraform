resource "google_project" "bitcoin_cash" {
  project_id      = var.project_id
  name            = var.project_name
  billing_account = var.billing_account
}

resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com"
  ])

  project            = google_project.bitcoin_cash.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_bigquery_dataset" "staging" {
  project     = google_project.bitcoin_cash.project_id
  dataset_id  = "staging"
  location    = var.region
  description = "Staging dataset for Bitcoin Cash transactions"
  depends_on  = [google_project_service.services]
}

resource "google_bigquery_dataset" "mart" {
  project     = google_project.bitcoin_cash.project_id
  dataset_id  = "data_mart"
  location    = var.region
  description = "Data mart for Bitcoin Cash analytics"
  depends_on  = [google_project_service.services]
}

resource "google_service_account" "dbt" {
  project      = google_project.bitcoin_cash.project_id
  account_id   = "dbt-service-account"
  display_name = "DBT BigQuery Service Account"
}

resource "google_project_iam_member" "bigquery_job_user" {
  project = google_project.bitcoin_cash.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "staging_editor" {
  project    = google_project.bitcoin_cash.project_id
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "mart_editor" {
  project    = google_project.bitcoin_cash.project_id
  dataset_id = google_bigquery_dataset.mart.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.bitcoin_cash.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"

  depends_on = [google_project_service.services]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.bitcoin_cash.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"

  display_name = "GitHub Actions Provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_workload_identity" {
  service_account_id = google_service_account.dbt.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${google_project.bitcoin_cash.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}