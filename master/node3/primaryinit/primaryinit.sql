CREATE USER 'repluser'@'%' IDENTIFIED BY 'replsecret';
GRANT REPLICATION SLAVE ON *.* TO 'repluser'@'%';
CREATE DATABASE primary_db;