#!/bin/bash -v
sudo apt-get update -y
#sudo apt-get dist-upgrade -y
sudo apt-get install -y nginx
sudo systemctl restart nginx.service