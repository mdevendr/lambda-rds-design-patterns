locals {
  account_id = data.aws_caller_identity.current.account_id

  # FIXED: .name deprecated → use .id
  region = data.aws_region.current.id

  vpc_cidr        = "XX.42.0.0/16"
  private_subnet1 = "XX.42.1.0/24"
  private_subnet2 = "XX.42.2.0/24"

  db_name     = "appdb"
  db_iam_user = "iam_app_user"

  lambda_name = "iam-mysql-proxy-test"
  proxy_name  = "iam-mysql-proxy"
}
