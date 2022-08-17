# Outline

## Redis Sentinel Configuration

1. Create base64 encoded Redis configuation
    ```sh
    echo '{"sentinels":[{"host":"redis-node-0.redis-headless.default.svc.cluster.local","port":26379},{"host":"redis-node-1.redis-headless.default.svc.cluster.local","port":26379},{"host":"redis-node-2.redis-headless.default.svc.cluster.local","port":26379}],"name":"redis-master","sentinelPassword":"<redis-sentinel-password>","password":"<redis-password>"}' \
        | base64
    ```

2. Use this base64 encoded string in the Kubernetes secret
    ```yaml
    REDIS_URL: ioredis://<encoded-base64>
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

3. Create `bucket-policy.json`
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
            "Sid": "BucketAccessForUser"
            }
        ]
    }
    ```

4. Apply the bucket policy
    ```sh
    mc admin policy add minio outline-bucket-policy bucket-policy.json
    ```

5. Associate policy with the user
    ```sh
    mc admin policy set minio outline-bucket-policy user=outline
    ```
