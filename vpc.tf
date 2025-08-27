variable "aws_vpc_config" {
  description = "Configuration of AWS VPC"
  type        = any
  default     = {}
}

variable "vpc_name" {
  type    = string
  default = "cbd-dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "vpc_azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "vpc_private_subnets" {
  type    = list(string)
  default = ["10.2.128.0/20", "10.2.144.0/20"]
}

variable "vpc_public_subnets" {
  type    = list(string)
  default = ["10.2.0.0/20", "10.2.16.0/20"]
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  type    = number
  default = 7

}

locals {
  #project_name = var.project_name
  #environment  = var.environment

  aws_vpc_main_defaults = {
    #project_name                                    = var.project_name#local.vpc_project_name
    #environment                                     = var.environment#local.vpc_environment
    vpc_name                                        = var.vpc_name #"${local.project_name}-${local.environment}-vpc"
    create_vpc                                      = true
    vpc_cidr                                        = var.vpc_cidr #"10.2.0.0/16"
    vpc_azs                                         = var.vpc_azs  #["ap-south-1a", "ap-south-1b"]
    vpc_public_subnets                              = var.vpc_public_subnets
    vpc_private_subnets                             = var.vpc_private_subnets #["10.2.128.0/20", "10.2.144.0/20"]
    enable_dns_hostnames                            = true
    enable_dns_support                              = true
    enable_nat_gateway                              = true
    single_nat_gateway                              = true
    one_nat_gateway_per_az                          = false
    map_public_ip_on_launch                         = false
    manage_default_security_group                   = false
    create_flow_log_cloudwatch_iam_role             = true
    create_flow_log_cloudwatch_log_group            = true
    enable_flow_log                                 = true
    flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days #7
  }

  aws_vpc_main = merge(local.aws_vpc_main_defaults, var.aws_vpc_config)
}



module "vpc" {
  count   = local.aws_vpc_main.create_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = local.aws_vpc_main.vpc_name
  cidr = local.aws_vpc_main.vpc_cidr

  azs             = local.aws_vpc_main.vpc_azs
  private_subnets = local.aws_vpc_main.vpc_private_subnets
  public_subnets  = local.aws_vpc_main.vpc_public_subnets

  enable_dns_hostnames = local.aws_vpc_main.enable_dns_hostnames
  enable_dns_support   = local.aws_vpc_main.enable_dns_support

  enable_nat_gateway     = local.aws_vpc_main.enable_nat_gateway
  single_nat_gateway     = local.aws_vpc_main.single_nat_gateway
  one_nat_gateway_per_az = local.aws_vpc_main.one_nat_gateway_per_az

  map_public_ip_on_launch       = local.aws_vpc_main.map_public_ip_on_launch
  manage_default_security_group = local.aws_vpc_main.manage_default_security_group

  create_flow_log_cloudwatch_iam_role             = local.aws_vpc_main.create_flow_log_cloudwatch_iam_role
  create_flow_log_cloudwatch_log_group            = local.aws_vpc_main.create_flow_log_cloudwatch_log_group
  enable_flow_log                                 = local.aws_vpc_main.enable_flow_log
  flow_log_cloudwatch_log_group_retention_in_days = local.aws_vpc_main.flow_log_cloudwatch_log_group_retention_in_days

  tags = {
    #Project     = local.project_name
    #Environment = local.environment
    # Name        = "${local.project_name}-${local.environment}-vpc"
    project     = var.project_name
    environment = var.environment
    name        = "${var.project_name}-${var.environment}-vpc"
  }
}

locals {
  aws_vpc_outputs = {
    vpc_id          = module.vpc[0].vpc_id
    public_subnets  = module.vpc[0].public_subnets
    private_subnets = module.vpc[0].private_subnets
    nat_gateway_ids = module.vpc[0].natgw_ids
    azs             = module.vpc[0].azs
  }
}