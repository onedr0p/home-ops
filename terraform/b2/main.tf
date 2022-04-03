terraform {

  backend "remote" {
    organization = "onedr0p"
    workspaces {
      name = "home-b2"
    }
  }

  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "0.8.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

data "sops_file" "b2_secrets" {
  source_file = "secret.sops.yaml"
}

provider "b2" {
  application_key_id = data.sops_file.b2_secrets.data["b2_application_key_id"]
  application_key    = data.sops_file.b2_secrets.data["b2_application_key"]
}

locals {
  bucket_settings = {
    "opnsense-d5b252ad" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
    "music-rcUFz3wc" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
    "cluster-app-data-xQdC743a" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
    "k3s-etcd-snapshots-s0DL5a1k" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
    "k10-home-p9FDifEu" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
    "k10-media-6bp9UzZu" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
    "k10-disaster-recovery-eKv4wYXE" = { bucket_type = "allPrivate", file_name_prefix = "", days_from_hiding_to_deleting = 1, days_from_uploading_to_hiding = null },
  }
}

resource "b2_bucket" "map" {
  for_each = local.bucket_settings

  bucket_name = each.key
  bucket_type = each.value.bucket_type

  # Keep only latest versions of the files
  # https://www.backblaze.com/b2/docs/lifecycle_rules.html
  lifecycle_rules {
    file_name_prefix              = each.value.file_name_prefix
    days_from_hiding_to_deleting  = each.value.days_from_hiding_to_deleting
    days_from_uploading_to_hiding = each.value.days_from_uploading_to_hiding
  }
}
