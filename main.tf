provider "aws" { // memanggil aws menggunakan access key dan secret key ke akunmu
  region = "us-east-1"
  access_key = "AKIA26M4WCIE2WGHAXEX"
  secret_key = "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"
}

# 1. Create VPC // create virtual private cloud 

resource "aws_vpc" "vpc1" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "terraformVPC"
  }
}

# 2. Create internet gateway agar instance ec2 terhubung ke internet jika memiliki aamat ip

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id 
}

# 3. Create custom route table untuk membantu router menentukan dimana network traffic dari subnet atau gateway diarahkan

resource "aws_route_table" "routeTable" {
  vpc_id = aws_vpc.vpc1.id 

  route { #create default route
    cidr_block = "0.0.0.0/0" #send all to internet gateway
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "routeTable"
  }
}

# 4. Create a subnet untuk membuat networks lebih efisien

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id 
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" #use specific availability zone. jadi within region terdapat 3-5 data center. 

  tags = {
    Name = "terraformSubnet"
  }
}

# 5. Associate subnet with route table agar subnetnya diarahkan

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routeTable.id
}

# 6. Create security group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" { #allow web traffic
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc1.id 

  ingress { //masuknya dibatasin
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #ip address manapun bisa akses
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #ip address manapun bisa akses
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #ip address manapun bisa akses
  }

  egress { //keluar ga dibatasin
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #any protocols
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-rr" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}

# 8. Assign an elastic ip to the network interface created in step 7 agar orang di internet bisa akses ini

resource "aws_eip" "one" { //membuat ip public
  vpc                       = true #karena kita pake vpc maka true
  network_interface         = aws_network_interface.web-server-rr.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw] #karena bergantung banget
}

# 9. Create ubuntu server and install/enable apache2 tp kita ntar pake nginx

resource "aws_instance" "web-server-instance" { // buat ubuntu
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a" #kalau ga hard code ini maka pick random availability zone.
  key_name = "WebServer"

  network_interface {
    device_index = 0 #first network interface that connect to device
    network_interface_id = aws_network_interface.web-server-rr.id
  }

  tags = {
    Name = "webserver"
  }
}

