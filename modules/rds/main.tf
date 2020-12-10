/*====
RDS
======*/

/* subnet used by rds */
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.environment}-rds-subnet-group"
  description = "RDS subnet group"
  subnet_ids  = "${compact(split(",", var.subnet_ids))}"




  // subnet_ids  = [module.networking.public_subnets_id]  
// subnet_ids = "${compact(split(",", var.subnet_ids))}"
  //       ["${aws_subnet.rds.*.id}"]

  tags = {
    Environment = "${var.environment}"
  }
}

/* Security Group for resources that want to access the Database */
resource "aws_security_group" "db_access_sg" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.environment}-db-access-sg"
  description = "Allow access to RDS"

  tags = {
    Name        = "${var.environment}-db-access-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-sg"
  description = "${var.environment} Security Group"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = "${var.environment}"
  }

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "TCP"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  // outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds" {
  identifier             = "${var.name}-${var.environment}-database"
  allocated_storage      = "${var.allocated_storage}"
  engine                 = "postgres"
  instance_class         = "${var.instance_class}"
  multi_az               = "${var.multi_az}"
  name                   = "${var.database_name}"
  username               = "${var.database_username}"
  password               = "${var.database_password}"
  db_subnet_group_name   = "${aws_db_subnet_group.rds_subnet_group.id}"
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
  skip_final_snapshot    = true
  publicly_accessible    = false

  # snapshot_identifier    = "rds-${var.environment}-snapshot"
  tags = {
    Name        = "${var.name}-${var.environment}-Database"
    Environment = "${var.environment}"
  }
}
