# variable "inst-names" {
#   type    = list(string)
#   default = ["var", "argume", "provisioners"]
# }
variable "ami-id" {
  type    = string
  default = "ami-0e1d06225679bc1c5"
}
variable "instance-type" {
  type    = string
  default = "t2.micro"
}
variable "security_group_rules" {
  type = map(map(string))
  default = {
    ssh = {
      from_port   = "22"
      to_port     = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
    http = {
      from_port   = "80"
      to_port     = "80"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
    https = {
      from_port   = "443"
      to_port     = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  } 
}
# variable "subnet-ids" {
#   type    = list(string)
#   default = local.subnet_ids
# }
variable "instance_count" {
  type    = number
  default = 2
}
variable "key-path" {
  type    = string
  default = "C:/Users/sajid/OneDrive/Desktop/my-keys/terraform.pem"
}