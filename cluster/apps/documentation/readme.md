# Documentation

## Outline

### Redis Sentinel Configuration

1. Create base64 encoded Redis configuation
    ```sh
    echo -n '{"db":15,"sentinels":[{"host":"redis-node-0.redis-headless.default.svc.cluster.local","port":26379},{"host":"redis-node-1.redis-headless.default.svc.cluster.local","port":26379},{"host":"redis-node-2.redis-headless.default.svc.cluster.local","port":26379}],"name":"redis-master"}' \
        | base64 -w 0
    ```

2. Use this base64 encoded string in the Kubernetes secret
    ```yaml
    REDIS_URL: ioredis://eyJkYiI6MTUsInNlbnRpbmVscyI6W3siaG9zdCI6InJlZGlzLW5vZGUtMC5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9LHsiaG9zdCI6InJlZGlzLW5vZGUtMS5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9LHsiaG9zdCI6InJlZGlzLW5vZGUtMi5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9XSwibmFtZSI6InJlZGlzLW1hc3RlciJ9
    ```

## S3 Configuration

1. Create `~/.mc/config.json`
    ```json
    {
        "version": "10",
        "aliases": {
            "minio": {
                "url": "https://s3.<domain>",
                "accessKey": "<access-key>",
                "secretKey": "<secret-key>",
                "api": "S3v4",
                "path": "auto"
            }
        }
    }
    ```

2. Create the outline user and password
    ```sh
    mc admin user add minio outline <super-secret-password>
    ```

3. Create the outline bucket
    ```sh
    mc mb minio/outline
    ```

4. Create `outline-user-policy.json`
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "s3:ListBucket",
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:DeleteObject"
                ],
                "Effect": "Allow",
                "Resource": ["arn:aws:s3:::outline/*", "arn:aws:s3:::outline"],
                "Sid": ""
            }
        ]
    }
    ```

5. Create `bucket-policy.json`
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:GetBucketLocation"
                ],
                "Resource": [
                    "arn:aws:s3:::outline"
                ]
            },
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::outline"
                ],
                "Condition": {
                    "StringEquals": {
                        "s3:prefix": [
                            "avatars",
                            "public"
                        ]
                    }
                }
            },
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:GetObject"
                ],
                "Resource": [
                    "arn:aws:s3:::outline/avatars*",
                    "arn:aws:s3:::outline/public*"
                ]
            }
        ]
    }
    ```

6. Apply the bucket policies
    ```sh
    mc admin policy add minio outline-private outline-user-policy.json
    ```

7. Associate private policy with the user
    ```sh
    mc admin policy set minio outline-private user=outline
    ```

8. Associate public policy with the bucket
    ```sh
    mc anonymous set-json bucket-policy.json minio/outline
    ```
