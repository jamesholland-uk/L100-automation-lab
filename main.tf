# Create the Resource Group.
resource "azurerm_resource_group" "this" {
  name     = coalesce("${terraform.workspace}-${var.name_prefix}${var.resource_group_name}", "${terraform.workspace}-$var.resource_group_name")
  location = var.location
}

# Generate a random password.
resource "random_password" "this" {
  length           = 16
  min_lower        = 16 - 4
  min_numeric      = 1
  min_upper        = 1
  special = false
}

# Create a bootstrap package to provide a base PAN-OS configration.
module "bootstrap" {
  source = "PaloAltoNetworks/vmseries-modules/azurerm//modules/bootstrap"
  version = "0.2.0"

  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  storage_account_name = "${terraform.workspace}${var.bootstrap_storage_account_name}"
  files                = var.bootstrap_files
}

# Create the network required for the topology.
module "vnet" {
  source  = "PaloAltoNetworks/vmseries-modules/azurerm//modules/vnet"
  version = "0.2.0"

  virtual_network_name    = var.virtual_network_name
  location                = var.location
  resource_group_name     = azurerm_resource_group.this.name
  address_space           = var.address_space
  network_security_groups = var.network_security_groups
  route_tables            = var.route_tables
  subnets                 = var.subnets
  tags                    = var.vnet_tags
}

# Allow inbound access to Management subnet.
resource "azurerm_network_security_rule" "mgmt" {
  name                        = "vmseries-mgmt-allow-inbound"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = "sg-mgmt"
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 1000
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = var.allow_inbound_mgmt_ips
  destination_address_prefix  = "*"
  destination_port_ranges     = ["443", "22"]

  depends_on = [module.vnet]
}

# Build the VM-Series firewall.
module "vmseries" {
  source  = "PaloAltoNetworks/vmseries-modules/azurerm//modules/vmseries"
  version = "0.2.0"

  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name                = "${var.name_prefix}firewall"
  avzone              = 1
  username            = var.username
  password            = coalesce(var.password, random_password.this.result)
  img_version         = var.vmseries_version
  img_sku             = var.vmseries_sku
  vm_size             = var.vmseries_vm_size
  bootstrap_storage_account = module.bootstrap.storage_account
  bootstrap_share_name      = module.bootstrap.storage_share.name
  tags                = var.vmseries_tags
  enable_zones        = var.enable_zones
  interfaces = [
    {
      name                = "fw-mgmt"
      subnet_id           = lookup(module.vnet.subnet_ids, "subnet-mgmt", null)
      create_public_ip    = true
      enable_backend_pool = false
    },
    {
      name                = "public-interface"
      subnet_id           = lookup(module.vnet.subnet_ids, "subnet-public", null)
      create_public_ip    = true
      enable_backend_pool = false
    },
    {
      name                = "inside-interface"
      subnet_id           = lookup(module.vnet.subnet_ids, "subnet-private", null)
      enable_backend_pool = false
    },
  ]
}

# Build the Linux host for performing activities.
module "mgmt_host" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/virtual_machine?ref=develop"
  # version = "0.2.0"

  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name                = "${var.name_prefix}mgmt-host"
  avzone              = 1
  username            = var.username
  password            = coalesce(var.password, random_password.this.result)
  img_publisher       = "Canonical"
  img_offer           = "0001-com-ubuntu-server-focal"
  img_sku             = "20_04-lts"
  vm_os_simple        = "UbuntuServer"
  enable_zones        = var.enable_zones
  interfaces = [
    {
      name                = "linux-mgmt"
      subnet_id           = lookup(module.vnet.subnet_ids, "subnet-mgmt", null)
      create_public_ip    = true
      enable_backend_pool = false
    }
  ]

  custom_data = base64encode(templatefile("./scripts/install_tools.sh", { terraform_version = "1.1.0" }))
}
