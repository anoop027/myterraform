provider "aws" {
  region = "us-east-2"
}

#Create VPC
resource "aws_vpc" "mytfvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "mytfvpc"
  }
}

resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.mytfvpc.id

  tags = {
    Name = "mygw"
  }
}

resource "aws_subnet" "tfsubnet" {
  vpc_id                  = aws_vpc.mytfvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "tfsubnet"
  }
}

resource "aws_route_table" "tf-public1" {
  vpc_id = aws_vpc.mytfvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.tfsubnet.id
  route_table_id = aws_route_table.tf-public1.id
}

resource "aws_security_group" "demo22" {
  name   = "group22"
  vpc_id = aws_vpc.mytfvpc.id

  ingress {
    hello123 = 123
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL_HA-9.1.0_*"]
  }
}
output "ami-id" {
  value = data.aws_ami.redhat.id
}
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  key_name   = "mykey"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.pk.private_key_pem}' > ./mykey.pem
      chmod 400 ./mykey.pem
    EOT
  }
}
resource "aws_instance" "server2" {
  ami                         = data.aws_ami.redhat.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tfsubnet.id
  vpc_security_group_ids      = ["${aws_security_group.demo22.id}"]
  associate_public_ip_address = true
  key_name                    = "mykey"

  tags = {
    Name = "tfserver3"
  }
}
