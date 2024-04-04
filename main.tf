terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  # instance_tenancy = "default"
  
  enable_dns_support = true ## error 3 - VPC does not support DNS resolution when creating a rds public
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}

resource "aws_eip" "ip-elastic" {
  instance = "${aws_instance.ec2-instance.id}"
  vpc      = true
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 3, 1)}"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  vpc_id      = aws_vpc.main.id
  description = "Allow all inbound traffic and all outbound traffic"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port = 0
   protocol = "-1"
  }

  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }

}

resource "aws_instance" "ec2-instance" {
  ami = "${var.ami_id}"
  instance_type = "t2.micro"
  subnet_id              = aws_subnet.main.id
  associate_public_ip_address = true
  key_name = "${var.ami_key_pair_name}"
  security_groups = [ aws_security_group.allow_all.id ]
  # vpc_security_group_ids = [aws_security_group.allow_all.id]
tags = {
  Name: "${var.ami_name}"
}
}

# Basic Usage RDS

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
  ] # minimum of two subnet IDs

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = true # error 2 - The specified VPC has no internet gateway attached

  identifier            = "my-rds-instance"
  storage_type          = "gp2"

  db_subnet_group_name  = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "My RDS Instance"
  }
}

# error 2 - The specified VPC has no internet gateway attached
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_main_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# resource "aws_key_pair" "ec2-key-pair" {
#   key_name   = "ec2-key-pair"
#   public_key = file("./ec2-key-pair.pub")
# }