provider "aws" {
  region = var.region
}

# ----------------------------
# VPC
# ----------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "hello-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway      = false
  single_nat_gateway      = false
  enable_dns_support      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# ----------------------------
# EKS
# ----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.23.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

 
  access_entries = {
    terraform-user = {
      kubernetes_groups = ["system:masters"]
      principal_arn     = "arn:aws:iam::585768155983:user/terraform-user"
    }
  }

  cluster_enabled_log_types     = []
  create_cloudwatch_log_group   = false
  create_kms_key                = false
  cluster_encryption_config     = {}

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  enable_irsa         = true
  authentication_mode = "API"

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"]

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# ----------------------------
# Kubernetes Provider
# ----------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.eks.cluster_name,
      "--region", var.region
    ]
  }
}
