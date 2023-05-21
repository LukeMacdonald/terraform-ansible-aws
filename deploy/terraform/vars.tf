variable "region" {
  type        = string
  description = "AWS region where resources are created"
}
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
  description = "Map of objects that contain the info relating to sunets (cidr block, subnet name & availability zone)"
}
variable "instance_names" {
  type        = list(string)
  description = "Stores a list of strings used for naming ec2 instances"
}
variable "bucket_details" {
  type        = map(string)
  description = "Stores data of the s3 bucket used for public key (name of bucket, key to public key stored in bucket)"
}
variable "sg_rule_types" {
  type        = set(string)
  description = "Stores the type of security group rules (ingress, egress)"
}
variable "sg_names" {
  type        = list(string)
  description = "Stores a list of strings used for naming security groups"
}
variable "http" {
  type        = number
  description = "Stores port number of HTTP Protocol"
}
variable "https" {
  type        = number
  description = "Stores port number of HTTP Protocol"
}
variable "postgres" {
  type        = number
  description = "Stores port number that Postgresql listens on"
}
variable "ssh" {
  type        = number
  description = "Stores port number for ssh connections"
}
variable "sg_rules" {
  type        = map(any)
  description = "Stores the common values used in initialising security group rules (protocol and cidr block)"
}