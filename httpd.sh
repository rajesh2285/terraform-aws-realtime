#!/bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
echo "This is AWS Acceptance Validation" > /var/www/html/index.html
