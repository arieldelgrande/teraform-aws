terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "zone-name"
    values = ["us-east-1a", "us-east-1b"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/publish-staging" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/publish-staging" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/publish-staging" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = "publish-staging"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets


  eks_managed_node_groups = {
    publish-staging = {
      name           = "publish-staging"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1

      capacity_type = "SPOT"

      # Enable autoscaling
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      # IAM configuration for ASG access
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        AutoScaling                  = "arn:aws:iam::aws:policy/AutoScalingFullAccess",
        ECRReadOnly                  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      # Spreading instances across subnets/AZs
      subnet_ids = module.vpc.private_subnets

      tags = {
        "k8s.io/cluster-autoscaler/enabled"         = "true"
        "k8s.io/cluster-autoscaler/publish-staging" = "owned"
      }
    }
  }

  tags = {
    Environment = "staging"
  }
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = "us-east-1"
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = "publish-staging" # Changed from test-cluster
}

output "nodegroup_name" {
  description = "Name of the EKS node group"
  value       = "publish-staging"
}