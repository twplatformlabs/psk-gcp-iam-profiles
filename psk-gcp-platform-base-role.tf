module "base-role" {
  source = "terraform-google-modules/iam/google//modules/custom_role_iam"
  #checkov:skip=CKV_TF_1
  version      = "8.1.0"
  target_level = "project"
  target_id    = var.gcp_project_id
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
  members              = ["serviceAccount:psk-gcp-platform-base-sa@${var.gcp_state_project_id}.iam.gserviceaccount.com"]
}
