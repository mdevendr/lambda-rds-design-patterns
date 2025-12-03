variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_master_username" {
  type    = string
  default = "admin"
}

variable "db_master_password" {
  type      = string
  sensitive = true
}

variable "db_iam_user" {
  type    = string
  default = "iam_user"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["xx.20.1.0/24", "xx.20.2.0/24"]
}

variable "lambda_function_name" {
  type    = string
  default = "lambda-rdsproxy-iam-mysql"
}

variable "lambda_zip_path" {
  description = "Path to the built Lambda ZIP (workflow will create this)"
  type        = string
  default     = "../lambda/build/lambda.zip"
}
