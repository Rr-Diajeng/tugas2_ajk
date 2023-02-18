# tugas2_ajk


## Identitas
| Name                                | NRP         |  
| ---                                 | ---         | 
| Rr. Diajeng Alfisyahrinnisa Anandha | 5025211147  |
| Ariella Firdaus Imata               | 5025211138  |

## IP Yang kita gunakan: http://54.90.184.9/

## Terraform

### Disini kita set up IaC yang tepat dan akan terhubung dengan AWS

``` Volt
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
### Install dependencies and add PHP8.0 repository

``` Volt
sudo apt-get install  ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
```

### install PHP8.0 version to run the Laravel Project
``` Volt
sudo apt-get update -y
sudo apt-get install php8.0-common php8.0-cli -y
```
### install PHP package
``` Volt
sudo apt-get install php8.0-mbstring php8.0-xml unzip composer -y
sudo apt-get install php8.0-curl php8.0-mysql php8.0-fpm -y
```

### Install mysql
``` Volt
sudo apt-get install mysql-server -y
```

### Set Mysql password
``` Volt
sudo apt-get install debconf-utils -y
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"
```

## Laravel Project
> Kita lakukan git clone di dalam `/var/www`
``` Volt
git clone https://gitlab.com/kuuhaku86/web-penugasan-individu.git
```

> lalu kita ubah folder `web-penugasan-individu` menjadi `project`

dengan

``` Volt
sudo mv web-penugasan-individu project
```

## Membuat new database
> kita akses root nya terlebih dahulu untuk membuat new database dan new user
``` Volt
sudo mysql -u root -p 
```

> Lalu kita buat new database
``` Volt
CREATE DATABASE ajk2;
```

> Lalu kita buat new user

``` Volt
CREATE USER 'kelompok4'@'%' IDENTIFIED BY 'kelompok4';
```

> Lalu kita beri new user akses ke database baru

``` Volt
GRANT ALL PRIVILEGES ON ajk2.* TO 'kelompok4'@'%' WITH GRANT OPTION;
```

> endingnya

``` Volt
FLUSH PRIVILEGES;
```

## Membuat environment application
### Disini kita gunakan directory `/var/www/project`

``` Volt
sudo cp .env.example .env
sudo nano /var/www/project/.env
```

> Di dalam environment, kita tambahkan debug

``` Volt
APP_DEBUG=true
LOG_DEBUG=true
```

> Sesuaikan DB_DATABASE, DB_USERNAME, DB_PASSWORD, ETC sesuai yang telah ditetapkan seperti

``` Volt
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=debug
LOG_DEBUG=true

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ajk2
DB_USERNAME=kelompok4
DB_PASSWORD=kelompok4
```

## Composer
### Kita lakukan upgrade Composer terlebih dahulu dengan
``` Volt

sudo which composer
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer

```

### Lalu kita lakukan composer install

``` Volt
sudo composer install
```

## Artisan
> Dapat dilakukan dengan

``` Volt
sudo php artisan key:generate
sudo php artisan migrate
```

## Apabila semua step terdapat eror maka langkah yang dapat dilakukan:

### remove default

``` Volt

sudo rm -rf /etc/nginx/sites-enabled/default
sudo service nginx reload

```

### Lalu lakukan

``` Volt
sudo chown -R $USER:www-data storage
sudo chown -R $USER:www-data bootstrap/cache
chmod -R 775 storage
chmod -R 775 bootstrap/cache
```

> Codingan diatas dilakukan apabila gagal deploy ke web






