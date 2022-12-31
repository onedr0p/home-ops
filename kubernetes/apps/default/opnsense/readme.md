# opnsense

## Minio Configuration

1. Create the Minio CLI configuration file (`~/.mc/config.json`)
    ```sh
    mc alias set minio https://s3.<domain> <access-key> <secret-key>
    ```

2. Create the bucket username and password
    ```sh
    mc admin user add minio opnsense-backup <super-secret-password>
    ```

3. Create the bucket
    ```sh
    mc mb minio/opnsense-backup
    ```

4. Create `/tmp/opnsense-backup-user-policy.json`
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
                "Resource": ["arn:aws:s3:::opnsense-backup/*", "arn:aws:s3:::opnsense-backup"],
                "Sid": ""
            }
        ]
    }
    ```

5. Apply the bucket policies
    ```sh
    mc admin policy add minio opnsense-backup-private /tmp/opnsense-backup-user-policy.json
    ```

6. Associate private policy with the user
    ```sh
    mc admin policy set minio opnsense-backup-private user=opnsense-backup
    ```
