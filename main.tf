terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
		}
	}
}

provider "aws" {
	region = "eu-central-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "main-vpc"
    }
}

resource "aws_subnet" "subnet_a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-central-1a"

    tags = {
        Name = "subnet-a"
    }
}

resource "aws_subnet" "subnet_b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-central-1b"

    tags = {
        Name = "subnet-b"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "igw"
    }
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "route-table"
    }
}

resource "aws_route_table_association" "rt_to_subnet_a" {
    subnet_id = aws_subnet.subnet_a.id
    route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "rt_to_subnet_b" {
    subnet_id = aws_subnet.subnet_b.id
    route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sec_group" {
    name = "pumpkingames_security_group"
    description =  "SSH from my IP, HTTP from anywhere"
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "p_games_sec_group"
    }

    ingress {
        description = "SSH from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["176.43.96.24/32"]
    }   

    ingress {
        description = "HTTP from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "ec2" {
    ami = "ami-09f224bab7225d943"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.subnet_a.id
    vpc_security_group_ids = [aws_security_group.sec_group.id]
    key_name = "pumpkin_key"
    associate_public_ip_address = true
    user_data_replace_on_change = true
    user_data = <<-EOF
        #!/bin/bash
        dnf install -y nginx
        systemctl enable --now nginx
        echo "Hello from Pumpkin Games" > /usr/share/nginx/html/index.html
      EOF

    tags = {
        Name = "pumpkin_instance"
    }
}

resource "aws_key_pair" "keypair" {
    key_name = "pumpkin_key"
    public_key = file("${path.module}/pumpkin-key.pub")
}

resource "aws_eip" "web" {
    domain = "vpc" 
    instance = aws_instance.ec2.id

    tags = {
        Name = "pumpkin_instance_eip"
    }   
}


