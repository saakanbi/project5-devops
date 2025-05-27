provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# HA VPC Module
# ----------------------------
module "vpc" {
  source                = "./modules/vpc"
  name                  = "project5"
  vpc_cidr              = "10.0.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  create_nat_gateway    = true
}

# ----------------------------
# Security Group
# ----------------------------
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH, HTTP, HTTPS, Jenkins, and Prometheus ports"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project5-sg"
  }
}

# ----------------------------
# EC2 - Flask App (Public Subnet)
# ----------------------------
module "flask_app" {
  source              = "./modules/ec2"
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_ids[0]
  key_name            = var.key_name
  security_group_ids  = [aws_security_group.allow_ssh_http.id]
  user_data           = file("./scripts/flask_user_data.sh")
  tags = {
    Name = "flask-app"
  }
}

# ----------------------------
# EC2 - Jenkins (Public Subnet)
# ----------------------------
module "jenkins" {
  source              = "./modules/ec2"
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_ids[1]
  key_name            = var.key_name
  security_group_ids  = [aws_security_group.allow_ssh_http.id]
  user_data           = file("./scripts/jenkins_user_data.sh")
  tags = {
    Name = "jenkins"
  }
}

# ----------------------------
# EC2 - SonarQube (Public Subnet)
# ----------------------------
module "sonarqube" {
  source              = "./modules/ec2"
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_ids[1]
  key_name            = var.key_name
  security_group_ids  = [aws_security_group.allow_ssh_http.id]
  user_data           = file("./scripts/sonarqube_user_data.sh")
  tags = {
    Name = "sonarqube"
  }
}

# ----------------------------
# EC2 - Nexus (Public Subnet)
# ----------------------------
module "nexus" {
  source              = "./modules/ec2"
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_ids[1]
  key_name            = var.key_name
  security_group_ids  = [aws_security_group.allow_ssh_http.id]
  user_data           = file("./scripts/nexus_user_data.sh")
  tags = {
    Name = "nexus"
  }
}

# ----------------------------
# EC2 - Monitoring (Prometheus + Grafana) (Public Subnet)
# ----------------------------
module "monitoring_stack" {
  source              = "./modules/ec2"
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_ids[0]
  key_name            = var.key_name
  security_group_ids  = [aws_security_group.allow_ssh_http.id]
  user_data           = file("./scripts/monitoring_user_data.sh")
  tags = {
    Name = "monitoring-stack"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project5-alb-sg"
  }
}

resource "aws_lb_target_group" "flask_tg" {
  name        = "flask-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "flask-target-group"
  }
}

resource "aws_lb" "flask_alb" {
  name               = "flask-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnet_ids

  tags = {
    Name = "flask-app-alb"
  }
}

resource "aws_lb_listener" "flask_listener" {
  load_balancer_arn = aws_lb.flask_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "flask_app" {
  target_group_arn = aws_lb_target_group.flask_tg.arn
  target_id        = module.flask_app.id
  port             = 80
}
