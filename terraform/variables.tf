variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of 3 public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of 3 private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.100.0/24","10.0.101.0/24","10.0.102.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones (3)"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

# variable "key_name" {
#   description = "EC2 key pair name to use for bastion (must exist)"
#   type        = string
# }

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to bastion (put your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ansible_git_repo" {
  type = string
  description = "Git URL of the Ansible playbooks repository"
}

variable "ansible_playbook_file" {
  type = string
  description = "Which playbook file in the repo to run"
}