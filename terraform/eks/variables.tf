
variable "environment" {
  default = "dev"
}

variable "cluster_name" {
  default = "hello-eks"
}



variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where EKS nodes will run"
  type        = list(string)
}
