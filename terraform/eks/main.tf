provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "hello-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_enabled_log_types = []  # Desactiva logs
  create_cloudwatch_log_group = false  # Evita que cree el log group
  
  create_kms_key               = false
  cluster_encryption_config = {}


  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  enable_irsa = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}


