output "instance_ip" {
  description = "Public IP address of the created instance"
  value       = linode_instance.odoo_instance.ip_address
}
