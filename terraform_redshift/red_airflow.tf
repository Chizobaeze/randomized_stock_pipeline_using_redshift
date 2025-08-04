# S3 Bucket for Infrastructure Data(to store all tf state file)
resource "aws_s3_bucket" "random_redshift_data" {
  bucket = "random-redshift-data"

  tags = {
    Name        = "My_infra_bucket"
    Environment = "production"
  }
}
# s3 bucket for my data that was uploaded to redshift
resource "aws_s3_bucket" "airflow_redshift" {
  bucket = "airflow-redshift-random"

  tags = {
    Name        = "My_infra_bucket"
    Environment = "production"
  }
}

# Create an IAM user (could be used for managing infrastructure)
resource "aws_iam_user" "chizoba_aws_red" {
  name = "chizoba_aws_red"
}

# IAM policy that allows services (like Redshift) to assume a role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"] 
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role Redshift will assume to access AWS resources like S3
resource "aws_iam_role" "redshift_role_rand" {
  name               = "chiz-redshift"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Create a custom VPC to isolate the Redshift infrastructure
resource "aws_vpc" "infrastructure_chiz" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "infrastructure_group"
  }
}

# Subnet inside the VPC where Redshift nodes will be launched
resource "aws_subnet" "redshift_chiz" {
  vpc_id     = aws_vpc.infrastructure_chiz.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "infrastructure_group"
  }
}

# Route table for the VPC (you can define internet routes here)
resource "aws_route_table" "chiz" {
  vpc_id = aws_vpc.infrastructure_chiz.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway_chiz.id
  }
}

# Internet gateway to allow public access from the VPC
resource "aws_internet_gateway" "gateway_chiz" {
  vpc_id = aws_vpc.infrastructure_chiz.id

  tags = {
    Name = "infrastructure_chiz"
  }
}

# Security group for the Redshift cluster
resource "aws_security_group" "group_chiz" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.infrastructure_chiz.id

  tags = {
    Name = "allow_tls"
  }
}

# Inbound rule: allow SSH (port 22) from within the VPC
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.group_chiz.id
  cidr_ipv4         = "102.88.111.39/32"
  from_port         =  5439
  ip_protocol       = "tcp"
  to_port           =  5439
}

# Outbound rule: allow all outgoing traffic
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.group_chiz.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Redshift cluster configuration
resource "aws_redshift_cluster" "doodle" {
  cluster_identifier           = "tf-redshift-cluster"           # Name of the cluster
  database_name                = "mydb"                          # Initial database name
  master_username              = "chiz_redshift"                 # Master username
  master_password              = data.aws_ssm_parameter.chiz_redshift.value  # Secure password from SSM
  node_type                    = "ra3.xlplus"                    # Node type (RA3 recommended)
  cluster_type                 = "single-node"                    # Multi-node cluster
  number_of_nodes              = 1                              # Number of nodes
  publicly_accessible          = true                            # Allow access from outside VPC
  iam_roles                    = [aws_iam_role.redshift_role_rand.arn]  # Attach IAM role
  cluster_subnet_group_name    = aws_redshift_subnet_group.infra-subnet_rand.name # Subnet group
}

# Securely retrieve the Redshift master password from SSM Parameter Store
data "aws_ssm_parameter" "chiz_redshift" {
  name            = "chiz_redshift"
  with_decryption = true
}

# Define a Redshift subnet group (Redshift needs at least one subnet group)
resource "aws_redshift_subnet_group" "infra-subnet_rand" {
  name       = "infra-group-rand"
  subnet_ids = [aws_subnet.redshift_chiz.id]
}

# Associate the route table with the subnet used by Redshift
resource "aws_route_table_association" "redshift_subnet_assoc" {
  subnet_id      = aws_subnet.redshift_chiz.id
  route_table_id = aws_route_table.chiz.id
}
