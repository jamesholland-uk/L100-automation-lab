output "username" {
  description = "Initial administrative username to use for VM-Series."
  value       = var.username
}

output "password" {
  description = "Initial administrative password to use for VM-Series."
  value       = coalesce(var.password, random_password.this.result)
  sensitive   = true
}

output "fw_mgmt_public_ip" {
  description = "Public IP Addresses for VM-Series management (https or ssh)."
  value       = module.vmseries.mgmt_ip_address
}

output "fw_mgmt_private_ip" {
  description = "Private IP Addresses for VM-Series management (https or ssh)."
  value       = module.vmseries.interfaces[0].ip_configuration[0].private_ip_address
}

output "mgmt_host_public_ip" {
  description = "IP Addresses for management host (ssh)."
  value       = module.mgmt_host.public_ips["linux-mgmt"]
}

