FROM mariadb:10.6

COPY galera.cnf /etc/mysql/conf.d/01-galera.cnf

