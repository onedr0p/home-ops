resource "minio_s3_bucket" "postgresql_bucket" {
  bucket = var.postgresql_bucket_name
  acl    = "private"
}

resource "minio_iam_user" "postgresql_user" {
  name          = var.postgresql_bucket_user
  secret        = var.postgresql_bucket_secret
  force_destroy = true
}

data "minio_iam_policy_document" "postgresql_user_policy_document" {
  statement {
    sid = ""
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${minio_s3_bucket.postgresql_bucket.bucket}/*",
      "arn:aws:s3:::${minio_s3_bucket.postgresql_bucket.bucket}"
    ]
  }
}

resource "minio_iam_policy" "postgresql_iam_policy" {
  name   = minio_s3_bucket.postgresql_bucket.bucket
  policy = data.minio_iam_policy_document.postgresql_user_policy_document.json
}

resource "minio_iam_user_policy_attachment" "postgresql_user_policy_attachment" {
  user_name   = minio_iam_user.postgresql_user.id
  policy_name = minio_iam_policy.postgresql_iam_policy.id
}
