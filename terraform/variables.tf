variable "location" {
  default = "norwayeast"
}
variable "resource_group_name" {
  default = "lt-tf-demo-rg"
}
variable "vnet_name" {
  default = "lt-tf-demo-vnet"
}
variable "subnet_name" {
  default = "lt-tf-demo-subnet"
}
variable "security_group_name" {
  default = "lt-tf-demo-nsg"
}
variable "nic_name" {
  default = "lt-tf-demo-nic1"
}
variable "nic_name_ipconf" {
  default = "lt-tf-demo-nic1-conf"
}
variable "vm1_name" {
  default = "lt-tf-demo-vm1"
}
variable "vm1_disk_name" {
  default = "lt-tf-demo-vm1-disk"
}
variable "vm1_key_name" {
  default = "lt-tf-demo-vm1-privatekey"
}
variable "kv_name" {
  default = "lt-tf-demo-kv"
}
variable "public_ip_name" {
  default = "lt-tf-demo-public-ip"
}
variable "fake_secret" {
  default = "zr78Q~BIKVs2gODLQeuDdacnm2hFo8_B1So4Qb8c"
}