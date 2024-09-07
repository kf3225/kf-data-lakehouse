output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "private subnetのID"
}
