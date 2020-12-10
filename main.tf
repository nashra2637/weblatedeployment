/*====
Variables used across all modules
======*/
locals {
  availability_zones = ["us-east-1a", "us-east-1b"]
}

provider "aws" {
  region = "${var.region}"
}

terraform {
  required_version = ">= 0.12"
}


module "networking" {
  source               = "./modules/networking"
  name                 = "${var.name}"
  environment          = "${var.environment}"
  vpc_cidr             = "${var.vpc_cidr}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  region               = "${var.region}"
  availability_zones   = "${local.availability_zones}"
}

module "rds" {
  source            = "./modules/rds"
  name              = "${var.name}"
  environment       = "${var.environment}"
  allocated_storage = "5"
  database_name     = "${var.database_name}"
  database_username = "${var.database_username}"
  database_password = "${var.database_password}"
  subnet_ids        = "${module.networking.private_subnets_id}"
  vpc_id            = "${module.networking.vpc_id}"
  vpc_cidr           = "${var.vpc_cidr}"
  instance_class    = "${var.instance_class}"
  multi_az          =  "${var.multi_az}"
}

module "ecs" {
  source             = "./modules/ecs"
  region             = "${var.region}"
  name               = "${var.name}"
  environment        = "${var.environment}"
  vpc_id             = "${module.networking.vpc_id}"
  vpc_cidr           = "${var.vpc_cidr}"
  availability_zones = "${local.availability_zones}"
  subnet_ids         = "${module.networking.private_subnets_id}"
  public_subnet_ids  = "${module.networking.public_subnets_id}"

  database_endpoint = "${module.rds.rds_address}"
  database_name     = "${var.database_name}"
  database_username = "${var.database_username}"
  database_password = "${var.database_password}"
  email_address     = "${var.email_address}"
}

module "codedeploy" {
  source                     = "./modules/code_deploy"
  name                       = "${var.name}"
  environment                = "${var.environment}"
  ecs_cluster_name           = "${module.ecs.cluster_name}"
  ecs_service_name           = "${module.ecs.service_name}"
  lb_listener_arns           = "${module.ecs.listener_arns}"
  blue_lb_target_group_name  = "${element(module.ecs.target_group_names, 0)}"
  green_lb_target_group_name = "${element(module.ecs.target_group_names, 1)}"
}

