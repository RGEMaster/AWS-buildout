provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "Primary_VPC" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_with_64_addresses" {
  vpc_id     = aws_vpc.Primary_VPC.id
  cidr_block = "10.0.0.0/26"
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.Primary_VPC.id

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

resource "aws_instance" "DC1" {
  ami           = "ami-0795faa4ab9bc8d8a"  # Amazon windows 2022 DC
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet_with_64_addresses.id

  security_groups = [
    aws_security_group.allow_ssh.id,
  ]

  tags = {
    Name = "DC1"
  }
}