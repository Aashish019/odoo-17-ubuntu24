terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

resource "linode_instance" "odoo_instance" {
  label     = var.linode_label
  image     = var.linode_image
  region    = var.linode_region
  type      = var.linode_type
  root_pass = var.root_password

  private_ip      = true
  backups_enabled = false

  tags = ["odoo"]
}
