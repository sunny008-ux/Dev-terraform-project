variable "aws_region" {
  type = string
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}
