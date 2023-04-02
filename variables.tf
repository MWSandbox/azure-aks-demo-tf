variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster"
}

variable "name" {
  type        = string
  default     = "aks-demo"
  description = "Naming for the resource created by terraform"
}

variable "admin_group_members" {
  type        = list(string)
  description = "Object IDs of Azure AD entities that will receive cluster-admin role in kubernetes rbac."
}

variable "key_vault_name" {
  type        = string
  description = "Name of the key vault used for disk encryption"
}

variable "kube_config_location" {
  type        = string
  description = "Will automatically update kube config in the provided location"
}