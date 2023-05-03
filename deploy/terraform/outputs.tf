# Output EC2 Instance Public IPs
output "app_instance1_ip" {
  value = aws_instance.a2-application[0].public_ip
}
output "app_instance2_ip" {
  value = aws_instance.a2-application[1].public_ip
}
output "db_ip" {
  value = aws_instance.a2-application[2].public_ip
}