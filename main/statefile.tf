terraform {
  backend "s3" {
    bucket       = "springapp-terraform-state-2025"
    key          = "terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}
