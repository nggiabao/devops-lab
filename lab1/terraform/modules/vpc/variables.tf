variable "project_name" {
  type        = string
  description = "Prefix đặt tên cho tài nguyên"
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
  default = "ap-southeast-1a"
}

variable "availability_zone_private" {
  type    = string
  default = "ap-southeast-1b"
}