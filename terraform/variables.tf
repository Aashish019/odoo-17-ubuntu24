variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "linode_region" {
  description = "Region to deploy the instance"
  type        = string
 # default     = "eu-central" # Frankfurt
}

variable "linode_type" {
  description = "Linode plan (size)"
  type        = string
  #default     = "g6-nanode-1" # 1 GB RAM, 1 CPU, 25 GB SSD
}

variable "linode_image" {
  description = "Image ID (Ubuntu 22.04)"
  type        = string
  #default     = "linode/ubuntu22.04"
}

variable "linode_label" {
  description = "Name (label) of the Linode instance"
  type        = string
}

variable "root_password" {
  description = "Root password for SSH login"
  type        = string
  sensitive   = true
}


