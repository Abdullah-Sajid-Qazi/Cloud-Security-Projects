variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cloudsec-vpc-iac"
}

variable "availability_zones" {
  description = "Availability Zones for the VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}