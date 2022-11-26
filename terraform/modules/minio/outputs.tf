output "outline_minio_user" {
  value = minio_iam_user.outline_user.id
}

output "outline_user_status" {
  value = minio_iam_user.outline_user.status
}

output "outline_user_secret" {
  value     = minio_iam_user.outline_user.secret
  sensitive = true
}
