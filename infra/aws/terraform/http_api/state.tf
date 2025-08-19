data "terraform_remote_state" "lambda" {
  backend = "local"
  config = {
    path = "${path.module}/../lambda_boot/terraform.tfstate"
  }
}