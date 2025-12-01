#!/bin/bash
set -e

DB_ID="mariadb-iam-test"
PROXY_NAME="mariadb-iam-proxy"
SUBNET_GROUP="mariadb-subnet-group"
ROLE_NAME="RDSProxyRole"
SG_DB="mariadb-db-sg"
SG_PROXY="mariadb-proxy-sg"

echo "Deleting Proxy..."
aws rds delete-db-proxy --db-proxy-name "$PROXY_NAME" --no-rollback >/dev/null || true

aws rds wait db-proxy-deleted --db-proxy-name "$PROXY_NAME" || true

echo "Deleting RDS instance..."
aws rds delete-db-instance \
  --db-instance-identifier "$DB_ID" \
  --skip-final-snapshot >/dev/null || true

aws rds wait db-instance-deleted --db-instance-identifier "$DB_ID" || true

echo "Deleting subnet group..."
aws rds delete-db-subnet-group --db-subnet-group-name "$SUBNET_GROUP" || true

echo "Deleting IAM role..."
aws iam detach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonRDSProxyServiceRole || true

aws iam delete-role --role-name "$ROLE_NAME" || true

echo "Deleting SGs..."
aws ec2 delete-security-group --group-name "$SG_DB" || true
aws ec2 delete-security-group --group-name "$SG_PROXY" || true

echo "Cleanup complete."
