provider "aws" {
  region = var.aws_region
  # AWS credentials will be provided by environment variables
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
}

# Create a VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "jenkins-vpc"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags = {
    Name = "jenkins-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "jenkins-subnet"
  }
}

# Create a route table
resource "aws_route_table" "jenkins_rtb" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }
  tags = {
    Name = "jenkins-rtb"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "jenkins_rtb_assoc" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_rtb.id
}

# Create a security group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow Jenkins traffic"
  vpc_id      = aws_vpc.jenkins_vpc.id

  # Jenkins web interface
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins web interface"
  }

  # Jenkins JNLP
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins JNLP"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# Create EC2 instance
resource "aws_instance" "jenkins_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.jenkins_subnet.id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "jenkins-server"
  }

  # This will create a local ansible inventory file
  provisioner "local-exec" {
    command = "echo '[jenkins]\\n${self.public_ip} ansible_user=${var.ssh_user}' > ../ansible/inventory"
  }
}

# Run Ansible playbook
resource "null_resource" "ansible_provisioner" {
  depends_on = [aws_instance.jenkins_server]

  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i inventory jenkins-playbook.yml"
  }
}