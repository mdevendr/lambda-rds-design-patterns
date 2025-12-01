#!/bin/bash
set -e

# -------------------------
# CONFIGURATION
# -------------------------
REGION="eu-west-2"
DB_ID="mariadb-iam-test"
PROXY_NAME="mariadb-iam-proxy"
DB_USER="iam_user"
DB_PWD="TempPassw0rd!"
SUBNET_GROUP="mariadb-subnet-group"
SG_DB="mariadb-db-sg"
SG_PROXY="mariadb-proxy-sg"
ROLE_NAME="RDSProxyRole"
ENGINE_VERSION="10.6.10"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Using AWS Account: $ACCOUNT_ID"
echo "Region: $REGION"


# -------------------------
# Create security groups
# -------------------------
echo "Creating SGs..."
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name "$SG_DB" \
  --description "DB SG" \
  --vpc-id $(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text) \
  --query GroupId --output text)

PROXY_SG_ID=$(aws ec2 create-security-group \
  --group-name "$SG_PROXY" \
  --description "Proxy SG" \
  --vpc-id $(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text) \
  --query GroupId --output text)

echo "Allow Proxy → DB"
aws ec2 authorize-security-group-ingress \
  --group-id "$DB_SG_ID" \
  --protocol tcp \
  --port 3306 \
  --source-group "$PROXY_SG_ID"


# -------------------------
# Subnet group
# -------------------------
VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text)
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[?MapPublicIpOnLaunch==\`false\`].SubnetId" --output text)

echo "Creating subnet group..."
aws rds create-db-subnet-group \
  --db-subnet-group-name "$SUBNET_GROUP" \
  --db-subnet-group-description "MariaDB IAM Test" \
  --subnet-ids $SUBNETS


# -------------------------
# Create RDS instance
# -------------------------
echo "Creating RDS instance (MariaDB $ENGINE_VERSION)..."

aws rds create-db-instance \
  --db-instance-identifier "$DB_ID" \
  --db-instance-class db.t3.micro \
  --engine mariadb \
  --master-username admin \
  --master-user-password "$DB_PWD" \
  --allocated-storage 20 \
  --engine-version "$ENGINE_VERSION" \
  --enable-iam-database-authentication \
  --db-subnet-group-name "$SUBNET_GROUP" \
  --vpc-security-group-ids "$DB_SG_ID" \
  --region "$REGION" \
  --publicly-accessible false

echo "Waiting for DB to become available..."
aws rds wait db-instance-available --db-instance-identifier "$DB_ID"


# -------------------------
# Create IAM Role for Proxy
# -------------------------
echo "Creating IAM role for RDS Proxy..."

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"rds.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }' >/dev/null

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonRDSProxyServiceRole

ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"


# -------------------------
# Create RDS Proxy
# -------------------------
echo "Creating RDS Proxy..."

aws rds create-db-proxy \
  --db-proxy-name "$PROXY_NAME" \
  --engine-family MYSQL \
  --auth "IAMAuth=REQUIRED" \
  --require-tls \
  --role-arn "$ROLE_ARN" \
  --vpc-subnet-ids $SUBNETS \
  --vpc-security-group-ids "$PROXY_SG_ID"

echo "Waiting for proxy..."
aws rds wait db-proxy-available --db-proxy-name "$PROXY_NAME"

# -------------------------
# Add target group
# -------------------------
aws rds register-db-proxy-targets \
  --db-proxy-name "$PROXY_NAME" \
  --db-instance-identifiers "$DB_ID"

echo "Proxy target registered."

# -------------------------
# Create IAM user in MariaDB
# -------------------------
echo "Creating DB IAM user..."

DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_ID" \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

mysql -h "$DB_ENDPOINT" -u admin -p"$DB_PWD" <<EOF
CREATE USER '$DB_USER' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER';
FLUSH PRIVILEGES;
EOF

echo "DONE: RDS + Proxy created."
