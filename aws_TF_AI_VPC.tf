################################################################
#terraform buildout code for AI VPCs                           #
################################################################


# Where are we doing this
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

# Create the EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create the EKS Cluster
resource "aws_eks_cluster" "TF_AI_EKS" {
  name     = "TF_AI_EKS_Cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.TF_AI_Subnet.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

  
  }

# Create the Worker Node Role
resource "aws_iam_role" "eks_node_role" {
  name = "eksNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create the Managed Node Group with 3 worker nodes
resource "aws_eks_node_group" "TF_AI_Node_Group" {
  cluster_name    = aws_eks_cluster.TF_AI_EKS.name
  node_group_name = "TF_AI_Node_Group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [aws_subnet.TF_AI_Subnet.id]

  scaling_config {
    desired_size = 375
    max_size     = 400
    min_size     = 120
  }

  instance_types = ["m5.large"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]
}

# Outputs
output "eks_cluster_name" {
  value = aws_eks_cluster.TF_AI_EKS.name
}

output "eks_node_group_name" {
  value = aws_eks_node_group.TF_AI_Node_Group.node_group_name
}

output "vpc_id" {
  value = aws_vpc.TF_AI_VPC.id
}

output "subnet_id" {
  value = aws_subnet.TF_AI_Subnet.id
}

output "security_group_id" {
  value = aws_security_group.allow_ssh.id
}