output "grafana_service_hostname" {
  description = "External DNS name for Grafana LoadBalancer"
  value       = try(helm_release.prometheus_stack.status[0].notes, "Run kubectl get svc -n monitoring")
}

output "prometheus_service_hostname" {
  description = "External DNS name for Prometheus LoadBalancer"
  value       = "Run kubectl get svc -n monitoring"
}
