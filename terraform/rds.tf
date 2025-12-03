
resource "aws_db_subnet_group" "mysql" {
  name       = "iam-mysql-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_parameter_group" "mysql" {
  name   = "iam-mysql-param-group"
  family = "mysql8.0"

  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "iam-mysql-db"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = local.db_name
  username = var.db_master_username
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.db_proxy.id]
  parameter_group_name   = aws_db_parameter_group.mysql.name

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 0
  skip_final_snapshot     = true

  iam_database_authentication_enabled = true
  deletion_protection                 = false

  tags = { Name = "iam-mysql-db" }
}

resource "aws_iam_role_policy" "lambda_rds_connect" {
  name = "lambda-rds-iam-connect"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["rds-db:connect"],
      Resource = [
        "arn:aws:rds-db:${local.region}:${local.account_id}:dbuser:${aws_db_instance.mysql.resource_id}/iam_app_user"
      ]
    }]
  })
}


resource "aws_iam_role" "rds_proxy" {
  name = "iam-mysql-rds-proxy-e2e-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "rds.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_proxy_connect" {
  name = "rds-proxy-e2e-connect"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "KMSPermissions"
        Effect = "Allow"
        Action = [
          "kms:ListAliases",
          "kms:GetPublicKey",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:eu-west-2:${local.account_id}:key/*"
        ]
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:eu-west-2:${local.account_id}:secret:*"
        ]
      },
      {
        Sid    = "RDSProxyIAMAuth"
        Effect = "Allow"
        Action = [
          "kms:GetPublicKey",
          "kms:Decrypt",
          "rds-db:connect",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:eu-west-2:${local.account_id}:key/*",
          "arn:aws:rds-db:eu-west-2:${local.account_id}:dbuser:${aws_db_instance.mysql.resource_id}/iam_app_user"
        ]
      }
    ]
  })
}

