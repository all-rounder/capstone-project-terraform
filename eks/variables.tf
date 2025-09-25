variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

# These should match how vpc-stack outputs them
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "capstone-project-eks-cluster"
}
