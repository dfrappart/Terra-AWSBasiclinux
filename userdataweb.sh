#!/bin/bash -v
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get install -y nginx > /tmp/nginx.log
sudo service nginx start