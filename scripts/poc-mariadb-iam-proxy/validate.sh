#!/bin/bash
set -e

REGION="eu-west-2"
DB_USER="iam_user"
PROXY_NAME="mariadb-iam-proxy"

PROXY_ENDPOINT=$(aws rds describe-db-proxies \
  --query "DBProxies[?DBProxyName=='$PROXY_NAME'].Endpoint" \
  --output text)

echo "Proxy endpoint: $PROXY_ENDPOINT"

TOKEN=$(aws rds generate-db-auth-token \
  --hostname "$PROXY_ENDPOINT" \
  --port 3306 \
  --region "$REGION" \
  --username "$DB_USER")

echo "Attempting IAM Auth through Proxy..."

mysql \
  --host="$PROXY_ENDPOINT" \
  --port=3306 \
  --user="$DB_USER" \
  --password="$TOKEN" \
  --ssl-mode=REQUIRED \
  -e "SELECT NOW();"

echo "Validation complete."
