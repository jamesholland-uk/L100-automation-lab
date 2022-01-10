location             = "UK South"
resource_group_name  = "l100-rg"
virtual_network_name = "vnet-vmseries"
address_space        = ["10.110.0.0/16"]
enable_zones         = true

network_security_groups = {
  "sg-mgmt"    = {}
  "sg-private" = {}
  "sg-public"  = {}
}

allow_inbound_mgmt_ips = [
  "0.0.0.0/0" # Example wide open access
]

route_tables = {
  private_route_table = {
    routes = {
      default = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.110.0.21"
      }
    }
  }
}

bootstrap_files = {
  "bootstrap/config/init-cfg.txt" = "config/init-cfg.txt"
  "bootstrap/config/bootstrap.xml" = "config/bootstrap.xml"
}

subnets = {
  "subnet-mgmt" = {
    address_prefixes       = ["10.110.255.0/24"]
    network_security_group = "sg-mgmt"
  }
  "subnet-private" = {
    address_prefixes       = ["10.110.0.0/24"]
    network_security_group = "sg-private"
    route_table            = "private_route_table"
  }
  "subnet-public" = {
    address_prefixes       = ["10.110.129.0/24"]
    network_security_group = "sg-public"
  }
}

vmseries_version = "10.1.3"
vmseries_sku     = "byol"