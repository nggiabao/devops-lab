variable "project_name" {
  type    = string
  default = "nt548-lab01"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "availability_zone_public" {
  type    = string
  default = "us-east-1a"
}

variable "availability_zone_private" {
  type    = string
  default = "us-east-1b"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "Ten EC2 Key Pair da tao tren AWS"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "IP public cua ban dang CIDR (vi du: 123.45.67.89/32)"
}