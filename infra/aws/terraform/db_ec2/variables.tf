# infra/aws/terraform/db_ec2/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "sessionhub"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "db_name" {
  type    = string
  default = "sessionhub"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type    = string
  default = "CHANGEME-REPLACE-ME"
}