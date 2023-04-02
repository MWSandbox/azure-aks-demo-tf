variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "aks_id" {
  type        = string
  description = "ID of the AKS cluster"
}

variable "members" {
  type = list(string)
}