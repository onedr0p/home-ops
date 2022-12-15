# Provider
variable "minio_server" {
  type = string
}
variable "minio_access_key" {
  type = string
}
variable "minio_secret_key" {
  type = string
}
variable "minio_region" {
  default = "us-east-1"
  type    = string
}
# Buckets
variable "outline_bucket_name" {
  default = "outlinetest"
  type    = string
}
variable "outline_bucket_user" {
  default = "outlinetest"
  type    = string
}
variable "outline_bucket_secret" {
  type = string
}
variable "postgresql_bucket_name" {
  default = "postgresqltest"
  type    = string
}
variable "postgresql_bucket_user" {
  default = "postgresqltest"
  type    = string
}
variable "postgresql_bucket_secret" {
  type = string
}
variable "volsync_bucket_name" {
  default = "volsync"
  type    = string
}
variable "volsync_bucket_user" {
  default = "volsync"
  type    = string
}
variable "volsync_bucket_secret" {
  type = string
}
variable "opnsense_backup_bucket_name" {
  default = "opnsense-backup"
  type    = string
}
variable "opnsense_backup_bucket_user" {
  default = "opnsense-backup"
  type    = string
}
variable "opnsense_backup_bucket_secret" {
  type = string
}
