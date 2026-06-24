variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "allowed_ssh_cidr" {
  type        = string
  description = "IP cua ban o dang CIDR, vi du: 123.45.67.89/32"
}