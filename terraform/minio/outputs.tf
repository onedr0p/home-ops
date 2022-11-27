output "bucket_outline_id" {
  value = minio_s3_bucket.outline_bucket.id
}
output "bucket_outline_status" {
  value = minio_iam_user.outline_user.status
}

output "bucket_postgresql_id" {
  value = minio_s3_bucket.postgresql_bucket.id
}
output "bucket_postgresql_status" {
  value = minio_iam_user.postgresql_user.status
}
