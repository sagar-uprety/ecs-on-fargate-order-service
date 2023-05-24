terraform {
  required_version = ">= 0.12"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "null" {
  # Configuration options
}

resource "null_resource" "example" {
}

