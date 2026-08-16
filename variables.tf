variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "key_name" {
  type    = string
  default = "terraform-ec2-key"
}