variable "region" {
  default     = "eu-west-2"
  description = "AWS region"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones for the VPC"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "cluster_name" {
  description = "Cluster Name"
  default     = "ECF-AI-APP"
}

variable "cluster_version" {
  description = "Kubernetes version for your EKS cluster"
  default     = "1.32"
}
