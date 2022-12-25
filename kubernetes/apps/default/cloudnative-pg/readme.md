# cloudnative-pg

## S3 Configuration

1. Create the Minio CLI configuration file (`~/.mc/config.json`)
    ```sh
    mc alias set minio https://s3.<domain> <access-key> <secret-key>
    ```

2. Create the postgresql user and password
    ```sh
    mc admin user add minio postgresql <super-secret-password>
    ```

3. Create the postgresql bucket
    ```sh
    mc mb minio/postgresql
    ```

4. Create `/tmp/postgresql-user-policy.json`
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
                "Resource": ["arn:aws:s3:::postgresql/*", "arn:aws:s3:::postgresql"],
                "Sid": ""
            }
        ]
    }
    ```

5. Apply the bucket policies
    ```sh
    mc admin policy add minio postgresql-private /tmp/postgresql-user-policy.json
    ```

6. Associate private policy with the user
    ```sh
    mc admin policy set minio postgresql-private user=postgresql
    ```
