resource "aws_security_group" "db_proxy" {
  name        = "iam-mysql-db-proxy-sg"
  description = "Allow MySQL from Lambda + EC2 helper"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from Lambda"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  ingress {
    description     = "MySQL from EC2 helper"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ssm_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group_rule" "db_proxy_self_reference" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_proxy.id
  security_group_id        = aws_security_group.db_proxy.id
  description              = "RDS Proxy self-communication"
}

resource "aws_security_group" "ssm_endpoints" {
  name        = "iam-mysql-ssm-endpoints-sg"
  description = "Allow 443 from VPC to SSM endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_proxy" "mysql_iam" {
  name          = local.proxy_name
  engine_family = "MYSQL"

  vpc_subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  vpc_security_group_ids = [aws_security_group.db_proxy.id]

  require_tls         = true
  idle_client_timeout = 1800

  # Enable true end-to-end IAM authentication
  default_auth_scheme = "IAM_AUTH"

  # IAM role used by proxy to authenticate to the DB
  role_arn = aws_iam_role.rds_proxy.arn
}


resource "aws_db_proxy_default_target_group" "mysql_iam" {
  db_proxy_name = aws_db_proxy.mysql_iam.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "mysql_iam" {
  db_proxy_name          = aws_db_proxy.mysql_iam.name
  db_instance_identifier = aws_db_instance.mysql.identifier
  target_group_name      = aws_db_proxy_default_target_group.mysql_iam.name
}

