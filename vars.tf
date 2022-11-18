variable "location" {
  type        = string
  description = "AWS location default"

}

variable "rg" {
  type        = string
  description = "Resource group name"
}

variable "app_name" {
  type        = string
  description = "application name"
}

variable "source_ip" {
  type        = string
  description = "source ip for ssh"
}

variable "ec2_ami_id" {
  type        = string
  description = "ec2 ami id"
}

variable "ec2_instance_type" {
  type        = string
  description = "ec2 instance type"
}