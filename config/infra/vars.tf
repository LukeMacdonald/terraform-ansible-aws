variable "path_to_ssh_public_key" {}
variable "my_ip_address" {}
variable "allow_all_ip_addresses_to_access_database_server" {}
variable "vpc_cidr" {
  type        = string
  description = "CIDR Block for the VPC"
}
variable "subnets" {
  type = map(object({
    cidr = string
    name = string
    az   = string
  }))
}
variable "vms" {}