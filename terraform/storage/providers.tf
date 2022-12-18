provider "kubernetes" {
  host                   = var.kubernetes_host
  client_certificate     = base64decode(data.sops_file.secrets.data["client_certificate"])
  client_key             = base64decode(data.sops_file.secrets.data["client_key"])
  cluster_ca_certificate = base64decode(data.sops_file.secrets.data["cluster_ca_certificate"])
}

provider "nexus" {
  alias    = "nas"
  insecure = true
  url      = var.nexus_url
  username = var.nexus_username
  password = var.nexus_password
}
