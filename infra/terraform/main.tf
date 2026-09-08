terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # After CHECKLIST.md step 1 (account + bucket), uncomment and fill in:
  # backend "s3" {
  #   bucket = "drachma-terraform-state"
  #   key    = "v1/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}
