variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "hello-app-cluster"
}

variable "cluster_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

