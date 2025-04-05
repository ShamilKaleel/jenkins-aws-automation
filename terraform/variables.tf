variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # More cost-effective option
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "blog-app-key" # Using your existing key
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance"
  type        = string
  default     = "ubuntu"
}