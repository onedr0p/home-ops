# Development

## Gitea

### S3 Configuration

1. Create the Minio CLI configuration file (`~/.mc/config.json`)
    ```sh
    mc alias set minio https://s3.<domain> <access-key> <secret-key>
    ```

2. Create the outline user and password
    ```sh
    mc admin user add minio gitea <super-secret-password>
    ```

3. Create the outline bucket
    ```sh
    mc mb minio/gitea
    ```

4. Create `/tmp/gitea-user-policy.json`
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
                "Resource": ["arn:aws:s3:::gitea/*", "arn:aws:s3:::gitea"],
                "Sid": ""
            }
        ]
    }
    ```

5. Apply the bucket policies
    ```sh
    mc admin policy add minio gitea-private /tmp/gitea-user-policy.json
    ```

6. Associate private policy with the user
    ```sh
    mc admin policy set minio gitea-private user=gitea
    ```
