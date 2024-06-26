#!/bin/bash
# Update the package listings
sudo yum update -y

# Install Nginx
sudo yum install nginx -y

# Start Nginx to make sure everything is fine
sudo service nginx start

# Enable Nginx to start on boot
sudo chkconfig nginx on

# Download the specified ZIP file
sudo wget -O /tmp/hexashop.zip https://www.free-css.com/assets/files/free-css-templates/download/page293/hexashop.zip

# Install unzip utility if it's not installed
sudo yum install unzip -y

# Unzip the content to the temporary directory
sudo unzip /tmp/hexashop.zip -d /tmp/hexashop

# Copy the unzipped content to the Nginx root directory
sudo cp -r /tmp/hexashop/templatemo_571_hexashop/* /usr/share/nginx/html/

# Change ownership and permissions
sudo chown -R nginx:nginx /usr/share/nginx/html/
sudo chmod -R 755 /usr/share/nginx/html/

# Restart Nginx to apply changes
sudo service nginx restart
