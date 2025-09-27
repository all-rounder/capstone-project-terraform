provider "aws" {
  region = var.aws_region
}

# --- Import EKS info from remote state ---
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "capstone-project-terraform-state-bucket"
    key    = "eks/terraform.tfstate"
    region = var.aws_region
  }
}

# --- Auth token for EKS ---
data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# --- Helm provider ---
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
