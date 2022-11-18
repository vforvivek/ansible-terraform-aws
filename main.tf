terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.location
}

resource "aws_resourcegroups_group" "monday_rg" {
  name = var.rg
  resource_query {
    query = <<JSON
{
    "ResourceTypeFilters": [
        "AWS::EC2::Instance",
        "AWS::S3::Bucket"
    ],
    "TagFilters": [
        {
            "Key": "Name",
            "Values": ["monday_app"]
        }
    ]
}
    JSON
  }
}

resource "aws_vpc" "monday_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.app_name
  }
}

resource "aws_subnet" "monday_subnet" {
  vpc_id                  = aws_vpc.monday_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    "Name" = var.app_name
  }
}

resource "aws_internet_gateway" "monday_igw" {
  vpc_id = aws_vpc.monday_vpc.id

  tags = {
    "Name" = var.app_name
  }
}

resource "aws_route_table" "monday_rt" {
  vpc_id = aws_vpc.monday_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monday_igw.id
  }

  tags = {
    "Name" = var.app_name
  }

}

resource "aws_route_table_association" "monday_rt_subnet" {
  subnet_id      = aws_subnet.monday_subnet.id
  route_table_id = aws_route_table.monday_rt.id
}

resource "aws_security_group" "monday_controlnode_sg" {
  name        = "control node"
  description = "allow ssh inbound traffic"
  vpc_id      = aws_vpc.monday_vpc.id

  ingress {
    description = "allow ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }

  egress {
    description = "internet access"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = var.app_name
  }

}

resource "aws_instance" "monday_ec2_controlnode" {
  ami             = var.ec2_ami_id
  instance_type   = var.ec2_instance_type
  subnet_id       = aws_subnet.monday_subnet.id
  security_groups = [aws_security_group.monday_controlnode_sg.id]

  tags = {
    "Name" = "${var.app_name}-control-node"
  }
}

resource "aws_security_group" "monday_web_sg" {
  name        = "web"
  description = "allow ssh and http traffic"
  vpc_id      = aws_vpc.monday_vpc.id

  ingress {
    description = "allow ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]

  }

  ingress {
    description = "allow http"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }

  tags = {
    "Name" = var.app_name
  }

}

resource "aws_instance" "monday_ec2_web" {
  ami             = var.ec2_ami_id
  instance_type   = var.ec2_instance_type
  subnet_id       = aws_subnet.monday_subnet.id
  security_groups = [aws_security_group.monday_web_sg.id]

  tags = {
    "Name" = "${var.app_name}-web"
  }
}

resource "aws_security_group" "monday_db_sg" {
  name        = "db"
  description = "allow ssh and sql traffic"
  vpc_id      = aws_vpc.monday_vpc.id

  ingress {
    description = "allow ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }

  ingress {
    description = "allow sql"
    from_port   = "3306"
    to_port     = "3306"
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }

  tags = {
    "Name" = var.app_name
  }

}

resource "aws_instance" "monday_ec2_db" {
  ami             = var.ec2_ami_id
  instance_type   = var.ec2_instance_type
  subnet_id       = aws_subnet.monday_subnet.id
  security_groups = [aws_security_group.monday_db_sg.id]

  tags = {
    "Name" = "${var.app_name}-db"
  }

}