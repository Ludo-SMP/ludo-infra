terraform {
  required_version = "~> 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "ludo-terraform-state-bucket-storage"
    prefix = "ludo/${var.env}/terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
