# outline

## Redis Sentinel Configuration

1. Create base64 encoded Redis configuation
    ```sh
    echo -n '{"db":15,"sentinels":[{"host":"redis-node-0.redis-headless.default.svc.cluster.local","port":26379},{"host":"redis-node-1.redis-headless.default.svc.cluster.local","port":26379},{"host":"redis-node-2.redis-headless.default.svc.cluster.local","port":26379}],"name":"redis-master"}' \
        | base64 -w 0
    ```

2. Use this base64 encoded string in the Kubernetes secret
    ```yaml
    REDIS_URL: ioredis://eyJkYiI6MTUsInNlbnRpbmVscyI6W3siaG9zdCI6InJlZGlzLW5vZGUtMC5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9LHsiaG9zdCI6InJlZGlzLW5vZGUtMS5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9LHsiaG9zdCI6InJlZGlzLW5vZGUtMi5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9XSwibmFtZSI6InJlZGlzLW1hc3RlciJ9
    ```
