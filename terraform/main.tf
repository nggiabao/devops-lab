terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "nt548-tfstate-ACCOUNT_ID"   # ← thay Account ID
    key            = "lab01/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "nt548-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name              = var.project_name
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidr        = var.public_subnet_cidr
  private_subnet_cidr       = var.private_subnet_cidr
  availability_zone_public  = var.availability_zone_public
  availability_zone_private = var.availability_zone_private
}

module "nat_gateway" {
  source = "./modules/nat_gateway"

  project_name     = var.project_name
  public_subnet_id = module.vpc.public_subnet_id

  # Dam bao IGW duoc tao truoc NAT GW
  depends_on = [module.vpc]
}

module "route_tables" {
  source = "./modules/route_tables"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_id
  private_subnet_id   = module.vpc.private_subnet_id
  internet_gateway_id = module.vpc.internet_gateway_id
  nat_gateway_id      = module.nat_gateway.nat_gateway_id
}

module "security_groups" {
  source = "./modules/security_groups"

  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type
  key_name          = var.key_name
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  public_sg_id      = module.security_groups.public_ec2_sg_id
  private_sg_id     = module.security_groups.private_ec2_sg_id
}