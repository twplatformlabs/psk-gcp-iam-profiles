#######
## Enable APIs needed for IAM
#######
resource "google_project_service" "state_iam_credentials" {
  count                      = var.provision_state_resources ? 1 : 0
  project                    = local.state_project_id
  service                    = "iamcredentials.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "state_iam" {
  count                      = var.provision_state_resources ? 1 : 0
  project                    = local.state_project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

#######
## Create Base service account
#######
resource "google_service_account" "psk_base" {
  count = var.provision_state_resources ? 1 : 0

  project      = local.state_project_id
  account_id   = "psk-gcp-platform-base-sa"
  display_name = "PSK GCP Platform Base Service Account"
  description  = "Service Account that can only assume other service account roles"
}

#######
## Setup workload identity pool for CI system to authenticate
#######
resource "google_iam_workload_identity_pool" "workload_identity_pool" {
  count = var.provision_state_resources ? 1 : 0

  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = var.workload_identity_pool_id
  description               = "Workload Identity Pool for CI orchestration"
  project                   = local.state_project_id
}

resource "google_iam_workload_identity_pool_provider" "workload_identity_pool_provider" {
  count = var.provision_state_resources ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.workload_identity_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
  project                            = local.state_project_id
  attribute_condition                = "assertion['oidc.circleci.com/vcs-origin'].startsWith(\"github.com/ThoughtWorks-DPS\")"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.aud"        = "assertion.aud"
    "attribute.project"    = "assertion['oidc.circleci.com/project-id']"
    "attribute.vcs_origin" = "assertion['oidc.circleci.com/vcs-origin']"
  }
  oidc {
    allowed_audiences = [var.circleci_org_id]
    issuer_uri        = "https://oidc.circleci.com/org/${var.circleci_org_id}"
  }
}

resource "google_service_account_iam_binding" "platform_base" {
  count              = var.provision_state_resources ? 1 : 0
  service_account_id = google_service_account.psk_base[0].name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "group:empc-na-platform-eng@thoughtworks.com"
  ]
}

#######
## Allow workload identity to impersonate base account
#######

resource "google_service_account_iam_binding" "admin-account-iam" {
  count = var.provision_state_resources ? 1 : 0

  service_account_id = google_service_account.psk_base[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.workload_identity_pool[0].name}/attribute.aud/${var.circleci_org_id}",
  ]
}

#######
## Ensure our pipeline can monitor the state account once bootstrapping is complete
#######
module "base-role-state" {
  count = var.provision_state_resources ? 1 : 0

  source = "terraform-google-modules/iam/google//modules/custom_role_iam"
  #checkov:skip=CKV_TF_1
  version      = "8.1.0"
  target_level = "project"
  target_id    = var.gcp_state_project_id
  role_id      = "pskGcpPlatformBaseRole"
  title        = "PSK GCP Platform Base Role"
  description  = "PSK Base role used by pipelines"
  base_roles   = []
  permissions = [
    "serviceusage.quotas.get",
    "serviceusage.services.get",
    "serviceusage.services.list",
    "iam.roles.get",
    "iam.serviceAccounts.getIamPolicy",
  ]
  excluded_permissions = []
  members = [
    "serviceAccount:psk-gcp-platform-base-sa@${var.gcp_state_project_id}.iam.gserviceaccount.com",
    "serviceAccount:psk-gcp-iam-profiles-sa@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]

  depends_on = [google_service_account.iam_profiles]
}

module "state-iam-profiles-role" {
  count = var.provision_state_resources ? 1 : 0

  source = "terraform-google-modules/iam/google//modules/custom_role_iam"
  #checkov:skip=CKV_TF_1
  version      = "8.1.0"
  target_level = "project"
  target_id    = var.gcp_state_project_id
  role_id      = "pskGcpPlatformIamProfilesRole"
  title        = "PSK GCP Platform IAM Profiles Role"
  description  = "Role used by terraform to manage IAM"
  base_roles = [
    "projects/${var.gcp_state_project_id}/roles/pskGcpPlatformBaseRole",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.workloadIdentityPoolAdmin"
  ]
  permissions = [
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.update",
    "iam.roles.undelete",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.serviceAccountKeys.create",
    "iam.serviceAccountKeys.delete",
    "iam.serviceAccountKeys.disable",
    "iam.serviceAccountKeys.enable",
    "iam.serviceAccountKeys.get",
    "iam.serviceAccountKeys.list",
    "iam.workloadIdentityPools.get",
    "iam.workloadIdentityPools.list",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy"
  ]
  excluded_permissions = ["resourcemanager.projects.list"]
  members              = ["serviceAccount:psk-gcp-iam-profiles-sa@${var.gcp_project_id}.iam.gserviceaccount.com"]

  depends_on = [google_service_account.iam_profiles, module.base-role-state]
}
