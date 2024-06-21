terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}


resource "aws_security_group" "strapi_sg" {
  name        = "ec2-SG-stap"
  description = "Strapi"

  vpc_id = "vpc-0361e4f0d39037892" # Replace with your VPC ID

  // Inbound rules (ingress)
  ingress {
    description = "Allow HTTP inbound traffic"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from all sources (for example)
  }

  ingress {
    description = "Allow SSH inbound traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your specific IP or range
  }
    // Outbound rules (egress)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic to all destinations
  }
}


resource "aws_instance" "strapi" {
  ami                         = "ami-0cf2b4e024cdb6960"
  instance_type               = "t2.medium"
  subnet_id              = "subnet-0983c7525ca9a3539"
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name = "PearlThoughts-serverKeys"
  associate_public_ip_address = true
  user_data                   = <<-EOF
                                #!/bin/bash
                                sudo apt update
                                curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
                                sudo bash -E nodesource_setup.sh
                                sudo apt update && sudo apt install nodejs -y
                                sudo npm install -g yarn && sudo npm install -g pm2
                                echo -e "skip\n" | npx create-strapi-app simple-strapi --quickstart
                                cd simple-strapi
                                echo "const strapi = require('@strapi/strapi');
                                strapi().start();" > server.js
                                pm2 start server.js --name strapi
                                pm2 save && pm2 startup
                                sleep 360
                                EOF

  tags = {
    Name = "Strapi_Server"
  }
}

output "instance_ip" {
  value = aws_instance.strapi.public_ip
}

