provider "aws" {
  region = local.region
}

locals {
  name   = "eyego-eks"
  region = "us-east-2"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-2a", "us-east-2b"]

  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Project = local.name
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets

  enable_nat_gateway = false
  enable_vpn_gateway = false

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true
  subnet_ids                     = module.vpc.public_subnets
  vpc_id                         = module.vpc.vpc_id
  

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.micro"]
    disk_size      = 10
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    free-tier-node-group = {
      desired_size = 1
      max_size     = 2
      min_size     = 1

      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = local.tags
}
