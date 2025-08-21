output "db_private_ip" { value = aws_instance.db.private_ip }
output "db_public_ip" { value = aws_instance.db.public_ip }