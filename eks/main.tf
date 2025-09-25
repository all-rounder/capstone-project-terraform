# Step 1: Import VPC info via remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "capstone-project-terraform-state-bucket"
    key            = "vpc/terraform.tfstate"
    region         = var.aws_region
    use_lockfile   = true
    encrypt        = true
  }
}

locals {
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  name_prefix     = "capstone-project"
  tags = {
    Project = local.name_prefix
    Owner   = "dev-team"
  }
}

# IAM role for control plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.name_prefix}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags = local.tags
}

data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# IAM role for worker nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${local.name_prefix}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
  tags = local.tags
}

data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_registry_read" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create the EKS cluster
resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.33"

  vpc_config {
    subnet_ids         = local.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-cluster" })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.service_policy
  ]
}

# On-demand node group
resource "aws_eks_node_group" "ondemand" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}-ondemand"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = local.private_subnets

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  capacity_type = "ON_DEMAND"
  instance_types = ["t3.medium"]
  disk_size      = 20

  tags = merge(local.tags, { Name = "${local.name_prefix}-ondemand-ng" })
}

# Spot node group
resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}-spot"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = local.private_subnets

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  capacity_type = "SPOT"
  instance_types = ["t3.medium"]
  disk_size      = 20

  tags = merge(local.tags, { Name = "${local.name_prefix}-spot-ng" })
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
