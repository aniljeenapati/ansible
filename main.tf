provider "google" {
  project = "primal-gear-436812-t0"
  region  = "us-central1"
}

resource "google_compute_instance" "centos_vm" {
  name         = "centos-vm2"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-stream-9"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "centos:${file("/root/.ssh/id_rsa.pub")}"
  }

  tags = ["http-server"]
}

output "vm_ip" {
  value = google_compute_instance.centos_vm.network_interface.0.access_config.0.nat_ip
}

resource "null_resource" "update_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      echo 'all:
  hosts:
    web:
      ansible_host: ${google_compute_instance.centos_vm.network_interface.0.access_config.0.nat_ip}
      ansible_user: centos
      ansible_ssh_private_key_file: /root/.ssh/id_rsa
' > /var/lib/jenkins/workspace/git-terra-ans/inventory.gcp.yml
    EOT
  }
  depends_on = [google_compute_instance.centos_vm]
}
