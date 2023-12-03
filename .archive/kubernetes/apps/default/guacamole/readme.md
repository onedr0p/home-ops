# guacamole

## Fix Database Permissions

1. Connect to Postgres
    ```sql
    export PGHOST=""
    export PGUSER="postgres"
    psql -d guacamole
    ```

2. Update Permissions
    ```sql
    GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO guacamole;
    GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO guacamole;
    ```

3. Debugging
    ```sql
    DROP DATABASE guacamole;
    DROP ROLE guacamole;
    ```
