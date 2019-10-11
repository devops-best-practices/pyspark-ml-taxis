variable "common_tags" {
  type = map(string)
  default = {
    builtWith      = "terraform"
    terraformGroup = "training-dmx"
  }
}

module "vpc" {
  source = "./vpc"
  name   = "training-vpc"

  cidr                 = "10.200.0.0/16"
  private_subnets      = ["10.200.1.0/24"]
  public_subnets       = ["10.200.101.0/24"]
  enable_nat_gateway   = "false"
  enable_s3_endpoint   = "true"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  azs                  = var.aws_availability_zones
  tags                 = var.common_tags
}

module "emr" {
  source  = "./emr"
  release = "emr-5.27.0"
  names   = ["kku"]
  # names = ["kku","cl1","cl2","cl3","cl4","cl5","cl6", "cl7","cl8"]
  applications     = ["Spark", "Hadoop", "Hue", "Hive", "Zookeeper"]
  master_type      = "m4.xlarge"
  master_ebs_size  = "40"
  master_bid_price = "0.09"
  worker_type      = "m4.2xlarge"
  worker_ebs_size  = "60"
  worker_bid_price = "0.18"
  worker_count     = 1
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnets
  ssh_key_ids      = [aws_key_pair.deployer.id]
  proxy_domain     = "training.dimajix-aws.net"
  proxy_user       = "data2day"
  proxy_password   = "dmx2019"
  tags             = var.common_tags
}

module "route53" {
  source    = "./route53"
  names     = module.emr.names
  targets   = module.emr.master_public_dns
  zone_name = "training.dimajix-aws.net"
  tags      = var.common_tags
}

