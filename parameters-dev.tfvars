region               = "us-east-1"
name                 = "spaceOS"
environment          = "dev"
vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]


database_name        = "weblate"
database_username    = "weblate"
database_password    = "test123"
multi_az             = "false"
instance_class       = "db.t2.small"

email_address        = "nashra2637@gmail.com"