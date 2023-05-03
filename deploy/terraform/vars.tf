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