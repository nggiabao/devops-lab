# Security Group cho Public EC2
resource "aws_security_group" "public_ec2" {
  name        = "${var.project_name}-public-ec2-sg"
  description = "Chỉ cho phép SSH từ IP cụ thể"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH từ IP được phép"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Cho phép tất cả outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-public-ec2-sg"
    Project = var.project_name
  }
}

# Security Group cho Private EC2
resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Chỉ cho phép SSH từ Public EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH từ Public EC2"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  egress {
    description = "Cho phép tất cả outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-private-ec2-sg"
    Project = var.project_name
  }
}