-- MySQL / Aurora MySQL
CREATE USER 'iam_user' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT SELECT, INSERT, UPDATE, DELETE ON mydb.* TO 'iam_user';
FLUSH PRIVILEGES;

-- PostgreSQL / Aurora PostgreSQL
CREATE ROLE iam_user LOGIN;
GRANT CONNECT ON DATABASE mydb TO iam_user;
GRANT USAGE ON SCHEMA public TO iam_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO iam_user;

-- Note:
-- IAM user/role must be mapped to this DB user using:
-- rds_iam = ON (parameter)
