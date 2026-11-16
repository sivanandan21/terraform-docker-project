terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "docker_server" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.docker_sg.id
  ]

  user_data = <<-EOF2
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    docker run -d --name nginx-server -p 80:80 nginx:alpine
  EOF2

  tags = {
    Name = "Terraform-Docker-Server"
  }
}

resource "aws_security_group" "docker_sg" {
  name = "terraform-docker-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "ami_id" {
  type = string
}

variable "allowed_cidr" {
  type = string
}

output "public_ip" {
  value = aws_instance.docker_server.public_ip
}
