variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "disk_encryption_set_id" {
  type = string
}

variable "admin_group_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kube_config_location" {
  type = string
}