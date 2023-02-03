terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "lt-dev-terraform"
    storage_account_name = "ltdevtf"
    container_name       = "terraform"
    key                  = "terraformgithubexample.tfstate"
  }
}

provider "azurerm" {
  features {}
}