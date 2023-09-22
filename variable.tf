################################################################################
# Input variables for the main.tf file
################################################################################

variable "environment" {
  description = "Working application environment eg: dev, stg, prd"
  type        = string
  default     = ""
}

variable "application" {
  description = "Name of the application"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region be used for all the resources"
  type        = string
  default     = "us-east-1"
}
variable "service" {
  description = "Name of the Service"
  type        = string
}


variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_port" {
  description = "value of the container port"
  type        = number
}

variable "imageurl" {
  description = "Image Url of the Image REPO"
  type        = string
}
