# Security Group cho Public EC2
resource "aws_security_group" "public_ec2" {
  name        = "${var.project_name}-public-ec2"
  description = "Chi cho phep SSH tu IP cu the"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH tu IP duoc phep"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Cho phep tat ca outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-public-ec2"
    Project = var.project_name
  }
}

# Security Group cho Private EC2
resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-private-ec2"
  description = "Chi cho phep SSH tu Public EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH tu Public EC2"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  ingress {
    description     = "App ports tu Jenkins (Public EC2)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  ingress {
    description     = "Backend API tu Jenkins (Public EC2)"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  egress {
    description = "Cho phep tat ca outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-private-ec2"
    Project = var.project_name
  }
}