provider "azurerm" {
  version = "~> 0.3"
}

module "os" {
  source       = "./os"
  vm_os_simple = "${var.vm_os_simple}"
}

resource "azurerm_virtual_machine_scale_set" "vm-linux" {
  count               = "${ contains(list("${var.vm_os_simple}","${var.vm_os_offer}"), "WindowsServer") ? 0 : 1 }"
  name                = "${var.vmscaleset_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"
  tags                = "${var.tags}"

  sku {
    name     = "${var.vm_size}"
    tier     = "Standard"
    capacity = "${var.nb_instance}"
  }

  storage_profile_image_reference {
    id        = "${var.vm_os_id }"
    publisher = "${coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher)}"
    offer     = "${coalesce(var.vm_os_offer, module.os.calculated_value_os_offer)}"
    sku       = "${coalesce(var.vm_os_sku, module.os.calculated_value_os_sku)}"
    version   = "${var.vm_os_version}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${ var.managed_disk_type }"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "${var.computer_name_prefix}"
    admin_username       = "${var.admin_username}"
    admin_password       = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_key}")}"
    }
  }

  network_profile {
    name    = "${var.network_profile}"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${var.vnet_subnet_id}"
      load_balancer_backend_address_pool_ids = ["${var.load_balancer_backend_address_pool_ids}"]
    }
  }

  extension {
    name                 = "vmssextension"
    publisher            = "Microsoft.OSTCExtensions"
    type                 = "CustomScriptForLinux"
    type_handler_version = "1.2"

    settings = <<SETTINGS
    {
        "commandToExecute": "${var.cmd_extension}"
    }
    SETTINGS
  }
}

resource "azurerm_virtual_machine_scale_set" "vm-windows" {
  count               = "${ contains(list("${var.vm_os_simple}","${var.vm_os_offer}"), "WindowsServer") ? 1 : 0 }"
  name                = "${var.vmscaleset_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"
  tags                = "${var.tags}"

  sku {
    name     = "${var.vm_size}"
    tier     = "Standard"
    capacity = "${var.nb_instance}"
  }

  storage_profile_image_reference {
    id        = "${ var.vm_os_id }"
    publisher = "${ coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher) }"
    offer     = "${ coalesce(var.vm_os_offer, module.os.calculated_value_os_offer) }"
    sku       = "${ coalesce(var.vm_os_sku, module.os.calculated_value_os_sku) }"
    version   = "${ var.vm_os_version }"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${ var.managed_disk_type }"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "${var.computer_name_prefix}"
    admin_username       = "${var.admin_username}"
    admin_password       = "${var.admin_password}"
  }

  network_profile {
    name    = "${var.network_profile}"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${var.vnet_subnet_id}"
      load_balancer_backend_address_pool_ids = ["${var.load_balancer_backend_address_pool_ids}"]
    }
  }

  extension {
    name                 = "vmssextension"
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.8"

    settings = <<SETTINGS
    {
        "commandToExecute": "${var.cmd_extension}"
    }
    SETTINGS
  }
}
