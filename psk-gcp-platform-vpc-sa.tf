resource "google_service_account" "vpc" {
  account_id   = "psk-gcp-platform-vpc-sa"
  display_name = "Service Account to manage VPCs and subnets"
}

module "vpc-role" {
  source = "terraform-google-modules/iam/google//modules/custom_role_iam"
  #checkov:skip=CKV_TF_1
  version      = "8.1.0"
  target_level = "project"
  target_id    = var.gcp_project_id
  role_id      = "pskGcpPlatformVpcRole"
  title        = "PSK GCP Platform VPC Role"
  description  = "Role used by terraform to manage VPCs and Subnets"
  base_roles = [
    "roles/compute.networkAdmin",
  ]
  permissions = []
  excluded_permissions = [
    "networksecurity.firewallEndpoints.create",
    "networksecurity.firewallEndpoints.delete",
    "networksecurity.firewallEndpoints.get",
    "networksecurity.firewallEndpoints.list",
    "networksecurity.firewallEndpoints.update",
    "networksecurity.firewallEndpoints.use",
    "resourcemanager.projects.list"
  ]
  members = ["serviceAccount:psk-gcp-platform-vpc-sa@${var.gcp_project_id}.iam.gserviceaccount.com"]

  depends_on = [google_service_account.vpc]
}

resource "google_service_account_iam_binding" "vpc" {
  service_account_id = google_service_account.vpc.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:psk-gcp-platform-base-sa@${var.gcp_state_project_id}.iam.gserviceaccount.com",
    "group:empc-na-platform-eng@thoughtworks.com"
  ]
}
