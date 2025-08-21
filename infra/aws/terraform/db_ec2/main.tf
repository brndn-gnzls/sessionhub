# --- Ubuntu 22.04 ARM64 AMI (Canonical owner 099720109477) ---
# Canonical documents how to find their AMIs & verify owner ID. 
# Name pattern for Jammy 22.04 ARM64 server images: ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*
data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
}
# :contentReference[oaicite:1]{index=1}

# --- IAM role & instance profile for Systems Manager (Session Manager, Run Command) ---
resource "aws_iam_role" "ssm_ec2_role" {
  name = "${var.project_name}-${var.env}-db-ssm-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.env}-db-ssm-profile"
  role = aws_iam_role.ssm_ec2_role.name
}
# :contentReference[oaicite:2]{index=2}

# --- Security group: re-use the DB SG created in VPC root (ingress from Lambda SG only) ---
locals {
  vpc_id        = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet = data.terraform_remote_state.vpc.outputs.public_subnet_id
  db_sg_id      = data.terraform_remote_state.vpc.outputs.db_sg_id
}

# --- User data (cloud-init) ---
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
    VPC_CIDR    = "10.42.0.0/16" # keep in sync with Root 1
  }
}

# --- EC2 instance ---
resource "aws_instance" "db" {
  ami                         = data.aws_ami.ubuntu_arm64.id
  instance_type               = "t4g.nano"
  subnet_id                   = local.public_subnet
  associate_public_ip_address = true

  vpc_security_group_ids = [local.db_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  # 20GB gp3
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = data.template_file.user_data.rendered

  tags = {
    Name    = "${var.project_name}-${var.env}-db"
    Project = var.project_name
    Env     = var.env
  }
}