output "flask_app_public_ip" {
  value = module.flask_app.public_ip
}

output "jenkins_stack_public_ip" {
  value = module.jenkins_stack.public_ip
}

output "monitoring_stack_public_ip" {
  value = module.monitoring_stack.public_ip
}

output "flask_alb_dns" {
  value = aws_lb.flask_alb.dns_name
}
