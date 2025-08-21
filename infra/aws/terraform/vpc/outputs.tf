output "vpc_id" { value = aws_vpc.main.id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "lambda_sg_id" { value = aws_security_group.lambda_sg.id }
output "db_sg_id" { value = aws_security_group.db_sg.id }
output "public_subnet_id" { value = aws_subnet.public.id }