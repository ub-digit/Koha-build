CREATE TABLE IF NOT EXISTS koha_deploy_instance_migrations (
  revision VARCHAR(255) PRIMARY KEY,
  migration_date DATETIME DEFAULT CURRENT_TIMESTAMP
);
