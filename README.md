# tugas2_ajk

## LOGIN CMD dengan SSH
1. Sebelum mulai menggunakan CMD, perhatikanlah public IP pada VM yang telah dibuat
2. Salinlah public IP tersebut, kemudian bukalah CMD
3. Ketikkanlah perintah "ssh @" pada CMD
4. Jika pada CMD terlihat aktivitas login terakhir, berarti koneksi dengan VM telah berhasil terbentuk.

## Konfigurasi firewall dengan ufw
Berikut ini adalah konfigurasi firewall dengan ufw:
1. sudo ufw allow 'Nginx HTTP' untuk port 80
2. sudo ufw allow 'Nginx HTTPS' untuk port 443
3. sudo ufw allow 'OpenSSH' untuk port 22
4. sudo ufw active untuk menyalakan firewall

## Install mysql server
1. sudo apt install mysql-server
2. sudo mysql
3. CREATE USER 'kelompok5'@'localhost' IDENTIFIED BY 'kelompok5'

## Install php
sudo apt install php-fpm php-mysql

## Membuat direktori website
1. sudo mkdir /var/www/kanza.akunlain.my.id mkdir untuk membuat direktori
2. sudo chown -R $USER:$USER /var/www/kanza.akunlain.my.id chown untuk mengubah permission user

## Konfigurasi Nginx
1. sudo nano /etc/nginx/sites-available/kanza.akunlain.my.id nano untuk membuat konfigurasi Nginx
2. sudo ln -s /etc/nginx/sites-available/kanza.akunlain.my.id /etc/nginx/sites-enabled/ ln untuk menyambungkan file pada sites-available
3. sudo unlink /etc.nginx/sites-enabled/default unlink untuk melepaskan konfigurasi default
4. sudo nginx -t untuk mengetes konfigurasi nginx
5. sudo systemctl reload nginx untuk mereload nginx

## Install aplikasi laravel
1. cd /var/www/kanza.akunlain.my.id/ cd untuk membuka direktori website
2. git clone https://gitlab.com/kuuhaku86/web-penugasan-individu.git . untuk mengunduh repo penugasan
3. apt install composer untuk menginstall composer
4. composer update untuk mengupdate paket-paket yang dibutuhkan
5. cp .env.example .env untuk mengkopi .env.example menjadi .env
6. nano .env untuk menambahkan username dan password mysql
7. php artisan key:generate perintah laravek pokoknya
8. php artisan migrate untuk menggenerate database
9. sudo chgrp -R www-data storage bootstrap/cache untuk mengubah permission folder
10. sudo chmod -R ug+rwx storage bootstrap/cache untuk mengubah permission folder

## Menambahkan konfigurasi SSL
1. apt install certbot untuk menginstall aplikasi certbot
2. sudo certbot certonly --webroot --webroot-path=/var/www/kanza.akunlain.my.id/public -d kanza.akunlain.my.id -d www.kanza.akunlain.my.id untuk menambahkan SSL pada DNS
