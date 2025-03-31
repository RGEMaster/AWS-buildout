################################################################
# Terraform buildout code for AI VPCs using EC2 & Packer      #
################################################################

# Define the provider
provider "aws" {
  region = "eu-west-2"
}

# Create the VPC
resource "aws_vpc" "TF_AI_VPC" {
  cidr_block = "10.0.0.0/16"
}

# Add the subnet to the VPC
resource "aws_subnet" "TF_AI_Subnet" {
  vpc_id     = aws_vpc.TF_AI_VPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Add the Internet Gateway
resource "aws_internet_gateway" "TF_AI_IGW" {
  vpc_id = aws_vpc.TF_AI_VPC.id
}

# Add a route table for public access
resource "aws_route_table" "TF_AI_Public_RT" {
  vpc_id = aws_vpc.TF_AI_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TF_AI_IGW.id
  }
}

resource "aws_route_table_association" "TF_AI_Public_Assoc" {
  subnet_id      = aws_subnet.TF_AI_Subnet.id
  route_table_id = aws_route_table.TF_AI_Public_RT.id
}

# Add the Security Group to the VPC
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

# Create an Auto Scaling Group for Kubernetes Nodes
resource "aws_launch_template" "TF_AI_K8S_LT" {
  name_prefix   = "TF_AI_K8S_"
  image_id      = "ami-0a94c8e4ca2674d5a"  # Replace with Packer-built AMI ID
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "TF_AI_K8S_Node"
    }
  }
}

resource "aws_autoscaling_group" "TF_AI_K8S_ASG" {
  vpc_zone_identifier  = [aws_subnet.TF_AI_Subnet.id]
  desired_capacity     = 2
  min_size            = 1
  max_size            = 5
  launch_template {
    id      = aws_launch_template.TF_AI_K8S_LT.id
    version = "$Latest"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.TF_AI_VPC.id
}

output "subnet_id" {
  value = aws_subnet.TF_AI_Subnet.id
}

output "security_group_id" {
  value = aws_security_group.allow_ssh.id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.TF_AI_K8S_ASG.id
}
