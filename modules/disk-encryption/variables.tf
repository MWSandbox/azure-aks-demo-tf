variable "name" {
  type = string
}

variable "unique_key_vault_name" {
  type = string
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}