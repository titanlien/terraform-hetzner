variable "hcloud_token" {
}

terraform {
  backend "s3" {
    bucket = "tfm-titan"
    key    = "hetzner/terraform.tfstate"
    region = "eu-central-1"
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

resource "hcloud_server" "hetzner-master" {
  name        = "master"
  image       = "centos-7"
  server_type = "cx11"
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
  server_id = "${hcloud_server.hetzner-master.id}"
  network_id = "${hcloud_network.privNet.id}"
  ip = "10.0.1.10"
}

output "public_ip4" {
  value = hcloud_server.hetzner-master.ipv4_address
}
