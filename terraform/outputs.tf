output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.address
}

output "ec2_instance_id" {
  value = aws_instance.ec2.id
}

output "frontend_url" {
  value = "http://${aws_lb.alb.dns_name}/"
}

output "api_productos_url" {
  value = "http://${aws_lb.alb.dns_name}/api/productos"
}

output "api_pedidos_url" {
  value = "http://${aws_lb.alb.dns_name}/api/pedidos"
}

output "ssm_connect_cmd" {
  value = "aws ssm start-session --target ${aws_instance.ec2.id} --region us-east-1"
}