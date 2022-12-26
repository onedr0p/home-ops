provider "minio" {
  minio_server   = "s3.devbu.io"
  minio_region   = "us-east-1"
  minio_user     = data.sops_file.secrets.data["minio_access_key"]
  minio_password = data.sops_file.secrets.data["minio_secret_key"]
  minio_ssl      = true
}
