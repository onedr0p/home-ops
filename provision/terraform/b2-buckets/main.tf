terraform {

  backend "remote" {
    organization = "onedr0p"
    workspaces {
      name = "home-b2"
    }
  }

  required_providers {
    b2 = {
      source = "Backblaze/b2"
      version = "0.7.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

data "sops_file" "b2_secrets" {
  source_file = "secret.sops.yaml"
}

provider "b2" {
  application_key_id = data.sops_file.b2_secrets.data["b2_application_key_id"]
  application_key = data.sops_file.b2_secrets.data["b2_application_key"]
}

resource "b2_bucket" "velero" {
  bucket_name = "velero-9a4g9czz"
  bucket_type = "allPrivate"
  # Keep only latest versions of the files
  # https://www.backblaze.com/b2/docs/lifecycle_rules.html
  lifecycle_rules {
    file_name_prefix = ""
    days_from_hiding_to_deleting = 1
    days_from_uploading_to_hiding = null
  }
}
