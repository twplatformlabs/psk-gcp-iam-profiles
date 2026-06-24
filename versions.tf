terraform {
  required_version = "~> 1.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "twdps"
    workspaces {
      prefix = "psk-gcp-iam-profiles-"
    }
  }
}

provider "google" {
  project                     = var.gcp_project_id
  impersonate_service_account = "psk-gcp-iam-profiles-sa@${var.gcp_project_id}.iam.gserviceaccount.com"
}

provider "random" {}
