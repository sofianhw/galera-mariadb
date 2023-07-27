docker run -d --restart=unless-stopped --net galera \
	--name node1 -h node1 --ip 172.100.0.101 \
	-p 3311:3306 \
	-v $(PWD)/master/node1/node1.cnf:/etc/mysql/conf.d/galera.cnf \
	-e MYSQL_ROOT_PASSWORD=root \
	sofianhw/galera --wsrep-new-cluster

docker run -d --restart=unless-stopped --net galera \
	--name node2 -h node2 --ip 172.100.0.102 \
	-p 3312:3306 \
	-v $(PWD)/master/node2/node2.cnf:/etc/mysql/conf.d/galera.cnf \
	-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
	sofianhw/galera

docker run -d --restart=unless-stopped --net galera \
	--name node3 -h node3 --ip 172.100.0.103 \
	-p 3313:3306 \
	-v $(PWD)/master/node3/node3.cnf:/etc/mysql/conf.d/galera.cnf \
	-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
	sofianhw/galera

docker run -d --restart=unless-stopped --net galera \
	--name node3-prim -h node3-prim --ip 172.100.0.103 \
	-p 3313:3306 \
	-v $(PWD)/master/node3/node3-prim.cnf:/etc/mysql/conf.d/galera.cnf \
	-v $PWD/master/node3/primaryinit:/docker-entrypoint-initdb.d:z \
	-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
	sofianhw/galera

docker run -d --restart=unless-stopped --net galera \
	--name node1-second -h node1-second --ip 172.100.0.104 \
	-p 3314:3306 \
	-v $(PWD)/replica/node1/config/secondary1.cnf:/etc/mysql/conf.d/galera.cnf \
	-v $(PWD)/replica/node1/config/slave.cnf:/etc/mysql/conf.d/slave.cnf \
	-v $PWD/replica/node1/sqlinit:/docker-entrypoint-initdb.d:z \
	-e MARIADB_ROOT_PASSWORD=secret \
	mariadb:10.6

docker run -d --restart=unless-stopped --net galera \
	--name node2-second -h node2-second --ip 172.100.0.105 \
	-p 3315:3306 \
	-v $(PWD)/replica/node2/config/secondary1.cnf:/etc/mysql/conf.d/galera.cnf \
	-v $(PWD)/replica/node2/config/slave.cnf:/etc/mysql/conf.d/slave.cnf \
	-v $(PWD)/replica/node2/config/ssl.cnf:/etc/mysql/conf.d/ssl.cnf \
	-v $PWD/replica/node2/sqlinit:/docker-entrypoint-initdb.d:z \
	-v $PWD/ssl:/etc/ssl/galera \
	-e MARIADB_ROOT_PASSWORD=secret \
	mariadb:10.6

docker exec -it node3-prim bash -c "until mysql -u root -p'root' -e 'SHOW STATUS LIKE \"wsrep_ready\";' | grep 'ON'; do sleep 1; done; mysql -u root -p'root' < /docker-entrypoint-initdb.d/primaryinit.sql"

docker run -d --restart=unless-stopped --net galera \
	--name node3-prim -h node3-prim --ip 172.100.0.103 \
	-p 3313:3306 \
	-v $(PWD)/master/node3/node3-prim.cnf:/etc/mysql/conf.d/galera.cnf \
	-v $PWD/master/node3/primaryinit:/docker-entrypoint-initdb.d:z \
	-v $(PWD)/master/node3/ssl.cnf:/etc/mysql/conf.d/ssl.cnf:z \
	-v $PWD/ssl:/etc/ssl/galera \
	-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
	sofianhw/ga