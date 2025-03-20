# Creating AWS Provider
provider "aws" {
  region = "us-east-1"
}

# STEP 01: A VPC with two subnets (one public, one private)

# Creating VPC
resource "aws_vpc" "my_vpc_2" {
  cidr_block = "10.0.0.0/16"
}

# Creating Public Subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc_2.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a" 
}

# Creating Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc_2.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"  
}

# Creating Private Subnet 2 (for RDS AZ coverage as the requirement is we need subnets to cover minimum 2 AZs)

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc_2.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
}

# STEP 02: An EC2 instance in the public subnet

# Security Group for EC2 instance

resource "aws_security_group" "ec2_sg_2" {
  vpc_id = aws_vpc.my_vpc_2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating the EC2 Instance
resource "aws_instance" "my_ec2_2" {
  ami                    = "ami-08b5b3a93ed654d19"  # Ensure this AMI is valid for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg_2.id]

}

# STEP 03: An RDS instance in the private subnet

# Security Group for RDS

resource "aws_security_group" "rds_sg_2" {
  vpc_id = aws_vpc.my_vpc_2.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg_2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Subnet Group

resource "aws_db_subnet_group" "my_db_subnet_group_2" {
  name       = "my-db-subnet-group-2"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]  # Ensure two different subnets for AZ coverage

}

# Creating the RDS instance

resource "aws_db_instance" "my_rds_2" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "sayeed"
  password             = "12345678"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}