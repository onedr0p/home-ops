resource "minio_s3_bucket" "outline_bucket" {
  bucket = var.outline_bucket_name
  acl    = "private"
}

resource "minio_iam_user" "outline_user" {
  name          = var.outline_bucket_user
  force_destroy = true
}

data "minio_iam_policy_document" "outline_user_policy_document" {
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
      "arn:aws:s3:::${minio_s3_bucket.outline_bucket.bucket}/*",
      "arn:aws:s3:::${minio_s3_bucket.outline_bucket.bucket}"
    ]
  }
}

resource "minio_iam_policy" "outline_iam_policy" {
  name      = minio_s3_bucket.outline_bucket.bucket
  policy    = data.minio_iam_policy_document.outline_user_policy_document.json
}

resource "minio_iam_user_policy_attachment" "outline_user_policy_attachment" {
  user_name   = minio_iam_user.outline_user.id
  policy_name = minio_iam_policy.outline_iam_policy.id
}

data "minio_iam_policy_document" "outline_bucket_policy_document" {
  statement {
    sid = "1"
    actions = ["s3:GetBucketLocation"]
    effect = "Allow"
    principal = "*"
    resources = ["arn:aws:s3:::${minio_s3_bucket.outline_bucket.bucket}"]
  }

  statement {
    actions = ["s3:ListBucket"]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        "avatars",
        "public",
      ]
    }
    effect = "Allow"
    principal = "*"
    resources = ["arn:aws:s3:::${minio_s3_bucket.outline_bucket.bucket}"]
  }

  statement {
    actions = ["s3:GetObject"]
    effect = "Allow"
    principal = "*"
    resources = [
      "arn:aws:s3:::${minio_s3_bucket.outline_bucket.bucket}/public*",
      "arn:aws:s3:::${minio_s3_bucket.outline_bucket.bucket}/avatars*"
    ]
  }
}

resource "minio_s3_bucket_policy" "outline_bucket_policy" {
  bucket = minio_s3_bucket.outline_bucket.bucket
  policy = data.minio_iam_policy_document.outline_bucket_policy_document.json
}
