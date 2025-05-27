# outputs.tf
output "flask_alb_dns" {
  value = aws_lb.flask_alb.dns_name
}

output "flask_app_public_ip" {
  value = module.flask_app.public_ip
}

output "jenkins_public_ip" {
  value = module.jenkins.public_ip
}

output "sonarqube_public_ip" {
  value = module.sonarqube.public_ip
}

output "nexus_public_ip" {
  value = module.nexus.public_ip
}

output "monitoring_stack_public_ip" {
  value = module.monitoring_stack.public_ip
}
