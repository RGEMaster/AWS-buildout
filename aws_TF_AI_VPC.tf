################################################################
# Terraform buildout code for AI VPCs using EC2, Packer & Kafka #
################################################################


################################################
#    AWS Configuration, EC2 build, installation#
#              and deployment                  #
################################################

# Define the provider
provider "aws" {
  region = "eu-west-2"
}

# Create the VPC
resource "aws_vpc" "TF_AI_VPC" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet
resource "aws_subnet" "TF_AI_Public_Subnet" {
  vpc_id                  = aws_vpc.TF_AI_VPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Public IPs enabled
}

# Create a private subnet
resource "aws_subnet" "TF_AI_Private_Subnet" {
  vpc_id                  = aws_vpc.TF_AI_VPC.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false  # No public IPs
}

# Add the Internet Gateway
resource "aws_internet_gateway" "TF_AI_IGW" {
  vpc_id = aws_vpc.TF_AI_VPC.id
}

# Allocate an Elastic IP for NAT Gateway
resource "aws_eip" "TF_AI_NAT_EIP" {
  domain = "vpc"
}

# Create the NAT Gateway
resource "aws_nat_gateway" "TF_AI_NAT" {
  allocation_id = aws_eip.TF_AI_NAT_EIP.id
  subnet_id     = aws_subnet.TF_AI_Public_Subnet.id
}

# Public Route Table
resource "aws_route_table" "TF_AI_Public_RT" {
  vpc_id = aws_vpc.TF_AI_VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TF_AI_IGW.id
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "TF_AI_Public_Assoc" {
  subnet_id      = aws_subnet.TF_AI_Public_Subnet.id
  route_table_id = aws_route_table.TF_AI_Public_RT.id
}

# Private Route Table
resource "aws_route_table" "TF_AI_Private_RT" {
  vpc_id = aws_vpc.TF_AI_VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.TF_AI_NAT.id
  }
}

# Associate private subnet with private route table
resource "aws_route_table_association" "TF_AI_Private_Assoc" {
  subnet_id      = aws_subnet.TF_AI_Private_Subnet.id
  route_table_id = aws_route_table.TF_AI_Private_RT.id
}

# Security Group allowing SSH access
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.TF_AI_VPC.id
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


###############################
#   Module Definitions        #
###############################


Module "Kafka_deploy"{

}
# Deploy Kafka using Helm
resource "helm_release" "kafka" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  namespace  = "kafka"
  create_namespace = true
  values = [<<EOF
replicaCount: 3
externalAccess:
  enabled: false
  service:
    type: ClusterIP
EOF
  ]
}
