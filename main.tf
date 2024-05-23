provider "azurerm" {
  features {}
}

# Resource Group for RDF4J
resource "azurerm_resource_group" "foo" {
  name     = "foo-resources"
  location = "East US"
}

# Virtual Network for RDF4J
resource "azurerm_virtual_network" "foo" {
  name                = "foo-network"
  resource_group_name = azurerm_resource_group.foo.name
  location            = azurerm_resource_group.foo.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet for RDF4J
resource "azurerm_subnet" "foo" {
  name                 = "foo-subnet"
  resource_group_name  = azurerm_resource_group.foo.name
  virtual_network_name = azurerm_virtual_network.foo.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for RDF4J VM
resource "azurerm_public_ip" "foo" {
  name                = "foo-public-ip"
  location            = azurerm_resource_group.foo.location
  resource_group_name = azurerm_resource_group.foo.name
  allocation_method   = "Dynamic"
}

# Network Interface for RDF4J VM
resource "azurerm_network_interface" "foo" {
  name                = "foo-network-interface"
  location            = azurerm_resource_group.foo.location
  resource_group_name = azurerm_resource_group.foo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.foo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.foo.id
  }
}

# Linux Virtual Machine for RDF4J
resource "azurerm_linux_virtual_machine" "foo" {
  name                = "azure-rdf4j"
  location            = azurerm_resource_group.foo.location
  resource_group_name = azurerm_resource_group.foo.name
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.foo.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/.ssh/id_rsa.pub")  # Path to your SSH public key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provision_vm_agent = true

  custom_data = base64encode(templatefile("${path.module}/install-rdf4j.sh", {}))
}

# Network Security Group for RDF4J VM
resource "azurerm_network_security_group" "foo" {
  name                = "foo-nsg"
  location            = azurerm_resource_group.foo.location
  resource_group_name = azurerm_resource_group.foo.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "66.117.193.162"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowFromAKS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "10.1.0.0/16"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    source_port_range          = "*"
  }

    security_rule {
    name                       = "AllowHTTP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"                # Allowing traffic from any source
    destination_address_prefix = "*"                # Allowing traffic to any destination
    destination_port_range     = "8080"
    source_port_range          = "*"                # Allowing traffic from any source port
  }
}

# Associate NSG with the Network Interface
resource "azurerm_network_interface_security_group_association" "foo" {
  network_interface_id      = azurerm_network_interface.foo.id
  network_security_group_id = azurerm_network_security_group.foo.id
}
