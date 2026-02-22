variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "az" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}