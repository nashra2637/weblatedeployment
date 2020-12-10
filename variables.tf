variable "region" {
  description = "Region that the instances will be created"
}

variable "name" {}

variable "environment" {}

variable "vpc_cidr" {}

variable "public_subnets_cidr" {}

variable "private_subnets_cidr" {}


/*====
environment specific variables
======*/

variable "multi_az" {}

variable "instance_class" {}

variable "database_name" {
  description = "The database name for Production"
}

variable "database_username" {
  description = "The username for the Production database"
}

variable "database_password" {
  description = "The user password for the Production database"
}

variable "email_address" {}


