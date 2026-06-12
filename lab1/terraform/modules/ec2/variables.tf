variable "project_name"      { type = string }
variable "ami_id"            { type = string }
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "key_name"          { type = string }
variable "public_subnet_id"  { type = string }
variable "private_subnet_id" { type = string }
variable "public_sg_id"      { type = string }
variable "private_sg_id"     { type = string }