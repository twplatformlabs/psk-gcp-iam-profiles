resource "google_service_account" "iam_profiles" {
  account_id   = "psk-gcp-iam-profiles-sa"
  display_name = "Service Account to manage IAM profiles"
}

module "iam-profiles-role" {
  source = "terraform-google-modules/iam/google//modules/custom_role_iam"
  #checkov:skip=CKV_TF_1
  version      = "8.2.0"
  target_level = "project"
  target_id    = var.gcp_project_id
  role_id      = "pskGcpPlatformIamProfilesRole"
  title        = "PSK GCP Platform IAM Profiles Role"
  description  = "Role used by terraform to manage IAM"
  base_roles = [
    "projects/${var.gcp_project_id}/roles/pskGcpPlatformBaseRole",
    "roles/serviceusage.serviceUsageAdmin",
  ]
  permissions = [
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.update",
    "iam.roles.undelete",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.delete",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.serviceAccountKeys.create",
    "iam.serviceAccountKeys.delete",
    "iam.serviceAccountKeys.disable",
    "iam.serviceAccountKeys.enable",
    "iam.serviceAccountKeys.get",
    "iam.serviceAccountKeys.list",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
  ]
  excluded_permissions = []
  members              = ["serviceAccount:psk-gcp-iam-profiles-sa@${var.gcp_project_id}.iam.gserviceaccount.com"]

  depends_on = [google_service_account.iam_profiles, module.base-role]
}

resource "google_service_account_iam_binding" "iam_profiles" {
  service_account_id = google_service_account.iam_profiles.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:psk-gcp-platform-base-sa@${var.gcp_state_project_id}.iam.gserviceaccount.com",
    "group:empc-na-platform-eng@thoughtworks.com"
  ]
}
