variable "aws_region" {
  default = "us-east-2"
}

variable "vpc_cidr_block" { default = "10.0.0.0/16"}
variable "vpc_tenancy" { default = "default"}
variable "aws_subnet" {
    type = "list"
    default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
}

data "aws_availability_zones" "azs" {}
