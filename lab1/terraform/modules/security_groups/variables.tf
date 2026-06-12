variable "project_name"     { type = string }
variable "vpc_id"           { type = string }
variable "allowed_ssh_cidr" {
  type        = string
  description = "IP của bạn ở dạng CIDR, ví dụ: 123.45.67.89/32"
}