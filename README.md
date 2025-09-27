# GitHub Repo

- https://github.com/all-rounder/capstone-project-terraform
- https://github.com/all-rounder/capstone-project-ansible

# Tech Stacks

- Terraform
- Ansible

# Tech Details

- Terraform template
- Optional: Terraform local-exec (ansible-playbook)
- Cloud-init (cc-ansible module not working, see at Issues)
- Ansible-pull (Login to bastion host)
- SSH keygen (cloud / local)
- Terraform remote status (connect to multi-part Terraform codes)

# Terraform

Two ways. First one is default.

```
# Use SSH key pair generated locally
terraform init && terraform apply -var 'allowed_ssh_cidr=<YOUR_IP>/32'

# Create SSH key pair on AWS before applying
terraform init && terraform apply -var 'key_name=...' -var 'allowed_ssh_cidr=<YOUR_IP>/32'
```

# Ansible

```
sudo apt install ansible-core
ansible-pull -U https://github.com/all-rounder/capstone-project-ansible.git bastion_setup.yml
```

# Parameters

- EC2 Instance Type (Bastion Host): T3.small
- EC2 Instance Type (EKS Cluster Nodes): T3.medium
- Kubernets version: 1.33

# EKS add-ons

- Amazon VPC CNI plugin for Kubernetes
- CoreDNS
- Kube-proxy
- Amazon EBS CSI driver
- Cert Manager
- Metrics Server: required for HPA.
- \*Fluent Bit

# Cluster tools

- AWS Load Balancer Controller
- ExternalDNS: syncs K8s Ingress/Service to Route53.
- Cluster Autoscaler: manages scaling node groups.
- Prometheus
- Grafana
- \*ElasticSearch
- \*Kibana
- \*Istio

# Load tests

# Issues

- cc-ansible module not working

  ```
  # Captures the output from each stage of cloud-init when it runs.
  $ less /var/log/cloud-init-output.log

  ...
  log_util.py[WARNING]: Running module ansible (<module 'cloudinit.config.cc_ansible' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_ansible.py'>) failed
  Cloud-init v. 25.1.4-0ubuntu0~24.04.1 finished

  # Very detailed log with debugging output, describing each action taken.
  $ less /var/log/cloud-init.log
  ```

- addons/main.tf

  I need to run `helm repo update` mannually, otherwise it throws errors

  ```
  │ Error: could not download chart: no cached repo found. (try 'helm repo update'): open C:\Users\ANDY'S~1\AppData\Local\Temp\helm\repository\grafana-index.yaml: The system cannot find the file specified.
  │
  │   with helm_release.alb_controller,
  │   on main.tf line 20, in resource "helm_release" "alb_controller":
  │   20: resource "helm_release" "alb_controller" {
  │
  ╵
  ╷
  │ Error: could not download chart: no cached repo found. (try 'helm repo update'): open C:\Users\ANDY'S~1\AppData\Local\Temp\helm\repository\grafana-index.yaml: The system cannot find the file specified.
  │
  │   with helm_release.prometheus_stack,
  │   on main.tf line 40, in resource "helm_release" "prometheus_stack":
  │   40: resource "helm_release" "prometheus_stack" {
  │
  ╵
  ╷
  │ Error: could not download chart: path "./helm-chart" not found
  │
  │   with helm_release.online_boutique,
  │   on main.tf line 63, in resource "helm_release" "online_boutique":
  │   63: resource "helm_release" "online_boutique" {

  ```
