variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "key_name" {
  type    = string
  default = "terraform-ec2-key"
}

variable "docker_image" {
  description = "Docker Hub image used by the EC2 web servers"
  type        = string
}