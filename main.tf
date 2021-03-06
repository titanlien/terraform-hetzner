variable "hcloud_token" {
}

variable "pvt_key" {
  default = "/Users/titan/.ssh/id_rsa"
}

terraform {
  backend "s3" {
    encrypt = true
    bucket = "tfstate-titan"
    key    = "hetzner/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

#  Main ssh key
resource "hcloud_ssh_key" "default" {
  name       = "personal ssh key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "hcloud_server" "master" {
  name        = "master"
  image       = "centos-7"
  server_type = "cx11-ceph"
  ssh_keys    = [hcloud_ssh_key.default.name]
  keep_disk   = true
  location    = "fsn1"
}

resource "hcloud_network" "privNet" {
  name     = "PrivNet"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "vlan1" {
  network_id = "${hcloud_network.privNet.id}"
  type = "server"
  network_zone = "eu-central"
  ip_range   = "10.0.1.0/24"
}

resource "hcloud_server_network" "srvnetwork" {
  server_id = "${hcloud_server.master.id}"
  network_id = "${hcloud_network.privNet.id}"
  ip = "10.0.1.10"
}

output "public_ip4" {
  value = hcloud_server.master.ipv4_address
}

resource "null_resource" "ansible-main" {
  triggers = {
    template_rendered = data.template_file.inventory.rendered
  }
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${hcloud_server.master.ipv4_address} >> ~/.ssh/known_hosts && ansible-playbook -e sshKey=${var.pvt_key} -i ./ansible/inventory --limit managers ./ansible/main.yml"
  }

  depends_on = ["hcloud_server.master", "null_resource.cmd"]
}
