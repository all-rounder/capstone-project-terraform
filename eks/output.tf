output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA certificate (base64 encoded)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "cluster_oidc_issuer" {
  description = "EKS cluster OIDC issuer URL"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_role_arn" {
  description = "IAM role ARN for worker node group(s)"
  value       = aws_iam_role.nodegroup.arn
}

output "vpc_id" {
  description = "VPC ID where the EKS cluster resides"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}