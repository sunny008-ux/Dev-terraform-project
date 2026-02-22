variable "vpc_id" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "user_data_file" {
  type        = string
  description = "Path of script file to run on EC2"
  default     = ""
}

variable "sg_id" {
  type = string
}
