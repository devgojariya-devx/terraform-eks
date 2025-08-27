variable "aws_eks_config" {
  description = "configuration of aws eks"
  type = any
  default = {}
}


locals {
  
  aws_eks_main_default = {

    name = "cbd-dev-cluster"
    kubernetes_version = "1.27"

    addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

    endpoint_public_access = false

    enable_cluster_creator_admin_permissions = true

    vpc_id = module.vpc[0].vpc_id
    subnet_ids = module.vpc[0].private_subnets
    control_plane_subnet_ids = module.vpc[0].private_subnets

    eks_managed_node_groups = {
        example = {
        
        ami_type       = "AL2_ARM_64"
        instance_types = ["m8g.medium"]

        min_size     = 2
        max_size     = 10
        desired_size = 2
        }
    }

  }
    eks_config = merge(local.aws_eks_main_default, var.aws_eks_config)
}


module "eks" {
  source =  "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = local.eks_config.name
  kubernetes_version = local.eks_config.kubernetes_version

  addons = local.eks_config.addons

  endpoint_public_access  = local.eks_config.endpoint_public_access

  enable_cluster_creator_admin_permissions = local.eks_config.enable_cluster_creator_admin_permissions

  vpc_id = local.eks_config.vpc_id
  subnet_ids = local.eks_config.subnet_ids
  control_plane_subnet_ids = local.eks_config.control_plane_subnet_ids

  eks_managed_node_groups = local.eks_config.eks_managed_node_groups

  tags = {

    environment = var.environment
    project_name = var.project_name
  }

}