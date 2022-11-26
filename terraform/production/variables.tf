# Minio

variable "minio_server" {
  description = "Minio Server Address"
  type        = string
}

variable "minio_access_key" {
  description = "Minio Access Key"
  type        = string
}

variable "minio_secret_key" {
  description = "Minio Secret Key"
  type        = string
}

variable "minio_region" {
  description = "Minio Region"
  default     = "us-east-1"
  type        = string
}
