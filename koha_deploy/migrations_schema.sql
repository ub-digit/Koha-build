CREATE TABLE IF NOT EXISTS koha_deploy_migrations (
  revision VARCHAR(255) PRIMARY KEY,
  filename varchar(255),
  migration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
