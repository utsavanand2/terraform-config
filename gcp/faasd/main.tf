terraform {
    required_version = ">= 0.12"
}

provider "google" {
    version         = "3.5.0"

    // Replace the file name with the service account credentials you created yourself
    credentials     = file("terraform-svc-acc.json")

    project         = "uts-1382"
    region          = "us-central1"
    zone            = "us-central1-a"
}

variable "ssh_key_file" {
    default     = "~/.ssh/id_rsa.pub"
    description = "Path to the SSH public key file"
}

resource "random_password" "password" {
    length  = 16
    special = true
    override_special = "_-#"
}

data "local_file" "ssh_key" {
    filename = pathexpand(var.ssh_key_file)
}

data "template_file" "cloud_init" {
    template = file("cloud-config.tpl")
    vars = {
        gateway_password = random_password.password.result,
        ssh_key = data.local_file.ssh_key.content,
    }
}

resource "google_compute_instance" "vm_instance" {
    name = "faasd-instance"
    machine_type = "f1-micro"
    tags = ["faasd"]
    metadata = {
        user-data = data.template_file.cloud_init.rendered
        ssh-key = "utsavanand:${data.local_file.ssh_key.filename}"
    }

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        network     = "default"
        access_config {
            // Include this section to give the VM an external IP address
        }
    }
}

output "password" {
    value = random_password.password.result
}

output "gateway_url" {
    value = "http://${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}:8080/"
}

output "login_cmd" {
    value = "faas-cli login -g http://${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}:8080/ -p ${random_password.password.result}"
}