# --- Namespace for monitoring ---
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# --- Service Account for AWS Load Balancer Controller ---
resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

# --- AWS Load Balancer Controller ---
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.0"

  values = [
    <<-EOT
    clusterName: ${data.terraform_remote_state.eks.outputs.cluster_name}
    serviceAccount:
      create: false
      name: aws-load-balancer-controller
    region: ${var.aws_region}
    vpcId: ${data.terraform_remote_state.eks.outputs.vpc_id}
    EOT
  ]
}

# --- Prometheus + Grafana ---
resource "helm_release" "prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "61.2.0"

  values = [
    <<-EOT
    grafana:
      adminPassword: "password"
      service:
        type: LoadBalancer
      ingress:
        enabled: false
    prometheus:
      service:
        type: LoadBalancer
    EOT
  ]
}

# --- GCP Online Boutique ---
resource "helm_release" "online_boutique" {
  name       = "online-boutique"
  repository = "https://github.com/GoogleCloudPlatform/microservices-demo.git"
  chart      = "./helm-chart"
  namespace  = "boutique"
  create_namespace = true
}
