provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "TF_AI_VPC" {
  cidr_block = "172.16.0.0/12"
}

resource "aws_subnet" "TF_AI_Subnet" {
  vpc_id     = aws_vpc.Primary_VPC.id
  cidr_block = "172.16.0.0/12"
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

