terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}


module "vpc" {
  source                = "../vpc"
  region                = var.region
  vpc_name              = "hello-vpc"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  azs                   = ["us-east-1a", "us-east-1b"]
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  cluster_name    = "hello-eks"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.public_subnet_ids
  vpc_id          = module.vpc.vpc_id

  enable_irsa = true

  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::585768155983:user/terraform-user"
      username = "terraform-user"
      groups   = ["system:masters"]
    }
  ]

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}
