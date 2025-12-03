output "db_proxy_endpoint" {
  value = aws_db_proxy.mysql_iam.endpoint
}

output "lambda_function_name" {
  value = aws_lambda_function.mysql_iam_test.function_name
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "ssm_ec2_instance_id" {
  value = aws_instance.ssm_helper.id
}

output "rds_mysql_endpoint" {
  value = aws_db_instance.mysql.address
}

output "rds_mysql_port" {
  value = aws_db_instance.mysql.port
}

# FIXED: dbi_resource_id → resource_id
output "rds_mysql_resource_id" {
  value = aws_db_instance.mysql.resource_id
}

output "rds_proxy_endpoint" {
  value = aws_db_proxy.mysql_iam.endpoint
}
