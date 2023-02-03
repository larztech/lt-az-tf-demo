data "azurerm_client_config" "current" {}

# Create Resource Group
resource "azurerm_resource_group" "rg1" {
  name     = var.resource_group_name
  location = var.location
  tags = {
   Environment = "Terraform Getting Started"
   Team = "DevOps"
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet1" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg1.name
}
  
# Create subnet
resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create subnet 2
resource "azurerm_subnet" "subnet2" {
  name                 = var.subnet2_name
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "nic1_ip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg1" {
  name                = var.security_group_name
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix= null
    source_application_security_group_ids = null
    destination_application_security_group_ids = [azurerm_application_security_group.asg1.id]
  }
  security_rule {
    name                       = "ASG1-SSHAllowOnly"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = null
    destination_address_prefix= null
    source_application_security_group_ids = [azurerm_application_security_group.asg1.id]
    destination_application_security_group_ids = [azurerm_application_security_group.asg2.id]
  }
}

# Create network interface
resource "azurerm_network_interface" "nic1" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  depends_on          = [azurerm_subnet.subnet1, azurerm_public_ip.nic1_ip]

  ip_configuration {
    name                          = "${var.nic2_name}-conf"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nic1_ip.id
  }
}

# Create network interface
resource "azurerm_network_interface" "nic2" {
  name                = var.nic2_name
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  depends_on          = [azurerm_subnet.subnet2]

  ip_configuration {
    name                          = "${var.nic2_name}-conf"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.nic2_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic1_nsg1_connect" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Connect the second security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic2_nsg1_connect" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Create servers ASG
resource "azurerm_application_security_group" "asg1" {
  name                = "tf-demo-asg-servers"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg1.name
}

# Create databases ASG
resource "azurerm_application_security_group" "asg2" {
  name                = "tf-demo-asg-databases"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg1.name
}

# Map ASGs to NICs
resource "azurerm_network_interface_application_security_group_association" "asgnic1" {
  network_interface_id          = azurerm_network_interface.nic1.id
  application_security_group_id = azurerm_application_security_group.asg1.id
}
resource "azurerm_network_interface_application_security_group_association" "asgnic2" {
  network_interface_id          = azurerm_network_interface.nic2.id
  application_security_group_id = azurerm_application_security_group.asg2.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg1.name
  }

  byte_length = 8
}

# Generate random text for a unique storage account name
resource "random_id" "random_id2" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg1.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage_boot_diagnostics" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg1.location
  resource_group_name      = azurerm_resource_group.rg1.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create second storage account for boot diagnostics
resource "azurerm_storage_account" "storage_boot_diagnostics2" {
  name                     = "diag${random_id.random_id2.hex}"
  location                 = azurerm_resource_group.rg1.location
  resource_group_name      = azurerm_resource_group.rg1.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create key vault
resource "azurerm_key_vault" "kv" {
  name                = var.kv_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg1.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

# Create key vault policy for this service principle
resource "azurerm_key_vault_access_policy" "kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "Set",
    "Purge",
    "Delete",
    "List",
  ]
}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_key1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_key2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload private key to Key Vault
data "azurerm_key_vault" "kv1" {
  name                        = var.kv_name
  resource_group_name         = azurerm_resource_group.rg1.name
  depends_on = [tls_private_key.ssh_key1,azurerm_key_vault_access_policy.kv_policy]
}

# Upload first key
resource "azurerm_key_vault_secret" "privatekey" {
  name         = "${var.vm1_name}-privatekey"
  value        = tls_private_key.ssh_key1.private_key_pem
  key_vault_id = data.azurerm_key_vault.kv1.id
}

# Upload second key
resource "azurerm_key_vault_secret" "privatekey2" {
  name         = "${var.vm2_name}-privatekey"
  value        = tls_private_key.ssh_key2.private_key_pem
  key_vault_id = data.azurerm_key_vault.kv1.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = var.vm1_name
  location              = azurerm_resource_group.rg1.location
  resource_group_name   = azurerm_resource_group.rg1.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  size                  = "Standard_B1S"

  os_disk {
    name                 = "${var.vm1_name}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  computer_name                   = var.vm1_name
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key1.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_boot_diagnostics.primary_blob_endpoint
  }
}

# Create second virtual machine
resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = var.vm2_name
  location              = azurerm_resource_group.rg1.location
  resource_group_name   = azurerm_resource_group.rg1.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  size                  = "Standard_B1S"

  os_disk {
    name                 = "${var.vm2_name}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  computer_name                   = var.vm2_name
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key2.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_boot_diagnostics2.primary_blob_endpoint
  }
}