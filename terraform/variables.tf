variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-03f4878755434977f" # Ubuntu 22.04 LTS in ap-south-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # More cost-effective option
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "blog-app" # Using your existing key
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/blog-app.pem"  # Adjust the default path as needed
}