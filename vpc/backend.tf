terraform {
  backend "s3" {
    bucket         = "capstone-project-terraform-state-bucket"
    key            = "vpc/terraform.tfstate"
    region         = "ap-southeast-2"
    use_lockfile   = true
    encrypt        = true
  }
}
