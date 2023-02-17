# tugas2_ajk


## Identitas
| Name                                | NRP         |  
| ---                                 | ---         | 
| Rr. Diajeng Alfisyahrinnisa Anandha | 5025211147  |
| Ariella Firdaus Imata               | 5025211138  |

## Terraform

### Disini kita set up IaC yang tepat dan akan terhubung dengan AWS

``` Volt
provider "aws" {
  region = "us-east-1"
  access_key = "AKIA26M4WCIE2WGHAXEX"
  secret_key = "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"
}

# 1. Create VPC

resource "aws_vpc" "vpc1" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "terraformVPC"
  }
}

# 2. Create internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id 
}

# 3. Create custom route table

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

# 4. Create a subnet

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id 
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" #use specific availability zone. jadi within region terdapat 3-5 data center. 

  tags = {
    Name = "terraformSubnet"
  }
}

# 5. Associate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routeTable.id
}

# 6. Create security group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" { #allow web traffic
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc1.id 

  ingress {
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

  egress {
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

resource "aws_eip" "one" {
  vpc                       = true #karena kita pake vpc maka true
  network_interface         = aws_network_interface.web-server-rr.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw] #karena bergantung banget
}

# 9. Create ubuntu server and install/enable apache2 tp kita ntar pake nginx

resource "aws_instance" "web-server-instance" {
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

```
## Nginx

> Kita lakukan `sudo apt-get install nginx -y`
> Lalu kita set firewall permission

``` Volt
echo "y" | sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 443
sudo ufw allow 80
sudo ufw allow 22
```

> Lalu kita buat directory baru `sudo mkdir /var/www/config`
> Lalu kita `sudo nano /var/www/config/example.conf`

yang berisi:

``` Volt
server {
        listen 80;
        root /var/www/project/public;
        index index.php index.html index.htm index.nginx-debian.html;

        server_name localhost;

        location / {
                try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}

```

> Lalu kita lakukan nginx config `sudo cp /var/www/config/example.conf /etc/nginx/sites-available/example.conf`
> Lalu kita sites-enabled directory dengan

``` Volt
sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled
sudo service nginx restart
```

## Konfigurasi lain
### 





