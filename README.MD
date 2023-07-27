# Database Clustering with Galera MariaDB

## Build docker image
$ docker build -t sofianhw/galera-mariadb

## Create docker network
$ docker network create --subnet 172.100.0.0/16 galera

## Create first master
$ docker run -d --restart=unless-stopped --net galera \
	--name node1 -h node1 --ip 172.100.0.101 \
	-p 3311:3306 \
	-v $(PWD)/master/node1/node1.cnf:/etc/mysql/conf.d/galera.cnf \
	-e MYSQL_ROOT_PASSWORD=root \
	sofianhw/galera-mariadb --wsrep-new-cluster

## Create second master
$ docker run -d --restart=unless-stopped --net galera \
	--name node2 -h node2 --ip 172.100.0.102 \
	-p 3312:3306 \
	-v $(PWD)/master/node2/node2.cnf:/etc/mysql/conf.d/galera.cnf \
	-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
	sofianhw/galera-mariadb

## Check number of nodes in cluster
$ docker exec -it node1 mariadb -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

## Create third master with slave replication config
$ docker run -d --restart=unless-stopped --net galera \
	--name node3-prim -h node3-prim --ip 172.100.0.103 \
	-p 3313:3306 \
	-v $(PWD)/master/node3/node3-prim.cnf:/etc/mysql/conf.d/galera.cnf \
	-v $PWD/master/node3/primaryinit:/docker-entrypoint-initdb.d:z \
	-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
	sofianhw/galera-mariadb

$ docker exec -it node3-prim bash -c "until mysql -u root -p'root' -e 'SHOW STATUS LIKE \"wsrep_ready\";' | grep 'ON'; do sleep 1; done; mysql -u root -p'root' < /docker-entrypoint-initdb.d/primaryinit.sql"

## Create slave node
docker run -d --restart=unless-stopped --net galera \
	--name node1-second -h node1-second --ip 172.100.0.104 \
	-p 3314:3306 \
	-v $(PWD)/replica/node1/config/secondary1.cnf:/etc/mysql/conf.d/galera.cnf \
	-v $PWD/replica/node1/sqlinit:/docker-entrypoint-initdb.d:z \
	-e MARIADB_ROOT_PASSWORD=secret \
	mariadb:10.6

## Check master and slave replication running
$ docker exec -it node1-second mariadb -uroot -psecret -e 'show slave status\G'
$ docker exec -it node3-prim mariadb -uroot -proot -e 'show master status\G'

