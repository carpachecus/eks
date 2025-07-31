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
# IAM Role for Terraform User
# ----------------------------
resource "aws_iam_role" "eks_access_role" {
  name = "eks-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::585768155983:user/terraform-user"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "eks-access-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
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
# aws-auth configmap
# ----------------------------
module "eks_aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.23.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_access_role.arn
      username = "eks-access-role"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::585768155983:user/terraform-user"
      username = "terraform-user"
      groups   = ["system:masters"]
    }
  ]

  depends_on = [module.eks]
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
      "--role-arn", aws_iam_role.eks_access_role.arn
    ]
  }
}
